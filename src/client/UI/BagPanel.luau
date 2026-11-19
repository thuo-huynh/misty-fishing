-- Bag panel: the Catches in the bag (Species, kg, sell price) and the total the market pays.
-- Display only: data comes from Sync; prices use the shared rule (Rules/Catch.sellPrice).
-- props = { data: Value(Profile data | nil), open: Value(boolean) }
local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local Content = require(RS:WaitForChild("Content"))
local Catch = require(RS:WaitForChild("Rules"):WaitForChild("Catch"))
local T = require(script.Parent:WaitForChild("T"))
local W = require(script.Parent:WaitForChild("Widgets"))
local Children = Fusion.Children

local GREY = Color3.fromRGB(110, 110, 110)

return function(scope, props)
	local data = props.data
	-- rows and the market total, recomputed on Sync
	local view = scope:Computed(function(use)
		local d = use(data)
		local rows, total = {}, 0
		for _, c in if d then d.bag else {} do
			local species = Content.species[c.species]
			local price = if species then Catch.sellPrice(species, c.kg) else 0
			if species and not c.kept then total += price end
			table.insert(rows, {
				color = if species then Color3.fromRGB(table.unpack(Content.rarities[species.rarity].color)) else GREY,
				text = T(if c.kept then "Bag_RowKept" else "Bag_Row", {
					name = if species then T(`species_{species.id}`, nil, species.name) else "???",
					kg = string.format("%.2f", c.kg), coins = price,
				}),
			})
		end
		return { rows = rows, title = T("Bag_Title", { count = d and #d.bag or 0, size = Content.balance.bagSize, coins = total }) }
	end)

	return W.Panel(scope, {
		Name = "Bag",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0.75, 0),
		BackgroundTransparency = 0,
		Visible = props.open,
		[Children] = {
			scope:New "UISizeConstraint" { MaxSize = Vector2.new(420, 520) },
			W.Label(scope, {
				Size = UDim2.new(1, -56, 0, 36), Position = UDim2.fromOffset(12, 4), Font = Enum.Font.GothamBlack, TextSize = 18,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = scope:Computed(function(use) return use(view).title end),
			}),
			W.Button(scope, {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(36, 36),
				Text = "X", onClick = function() props.open:set(false) end,
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
						local labels = {}
						for i, r in use(view).rows do
							table.insert(labels, W.Label(scope, {
								LayoutOrder = i, Size = UDim2.new(1, -8, 0, 22), TextSize = 14, TextColor3 = r.color, Text = r.text,
							}))
						end
						return labels
					end),
				},
			},
		},
	})
end
