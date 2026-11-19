-- Shop panel, opened by a shop's ProximityPrompt: the Tackle's price and stats compared with what is equipped.
-- props = { data: Value(Profile data | nil), item: Value({ kind, id } | nil), usable(kind, id) -> boolean,
--           onBuy(kind, id), onEquip(kind, id) }
local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local Content = require(RS:WaitForChild("Content"))
local T = require(script.Parent:WaitForChild("T"))
local W = require(script.Parent:WaitForChild("Widgets"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Children, peek = Fusion.Children, Fusion.peek

local SLOT = { rods = "rod", lines = "line", baits = "bait" }
-- stats shown per kind, compared with the equipped Tackle
local STATS = { rods = { "power", "luck", "maxKg", "pull" }, lines = { "maxTension" }, baits = { "luck", "biteSpeed" } }

return function(scope, props)
	local data, item = props.data, props.item
	-- everything the panel shows, recomputed on Sync or when another shop opens; nil hides the panel
	local view = scope:Computed(function(use)
		local d, it = use(data), use(item)
		if not d or not it then return nil end
		local kind, id = it.kind, it.id
		local rec, cur = Content[kind][id], Content[kind][d.equipped[SLOT[kind]]]
		local lines = {}
		for _, k in STATS[kind] do
			table.insert(lines, T("Shop_Stat", {
				stat = T(`Stat_{k}`, nil, k), value = rec[k], equipped = cur[k], delta = string.format("%+g", rec[k] - cur[k]),
			}))
		end
		-- shortcut: no Level line; Tackle content has no `level` field yet
		if kind == "baits" then table.insert(lines, T("Shop_Have", { count = d.baits[id] or 0 })) end
		local owned = props.usable(kind, id)
		local args = { name = T(`{kind}_{id}`, nil, rec.name), price = rec.price, pack = rec.pack }
		return {
			title = T(if kind == "baits" then "Shop_TitlePack" else "Shop_Title", args),
			stats = table.concat(lines, "\n"),
			buy = if kind == "baits" or not owned then T(if kind == "baits" then "Shop_BuyPack" else "Shop_Buy", args) else nil,
			equip = owned and d.equipped[SLOT[kind]] ~= id,
		}
	end)
	-- empty: the value while the panel is hidden (Fusion can't assign nil to Text/Visible)
	local function field(fn, empty)
		return scope:Computed(function(use)
			local v = use(view)
			if v then return fn(v) else return empty end
		end)
	end
	local function act(fn)
		return function()
			local it = peek(item)
			if it then fn(it.kind, it.id) end
		end
	end

	return W.Panel(scope, {
		Name = "Shop",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(0.9, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		solid = true,
		Visible = field(function() return true end, false),
		[Children] = {
			scope:New "UISizeConstraint" { MaxSize = Vector2.new(380, math.huge) },
			scope:New "UIListLayout" { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder },
			scope:New "UIPadding" {
				PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20),
				PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 20),
			},
			W.Label(scope, { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 30), FontFace = Theme.display, TextSize = 26,
				Text = field(function(v) return v.title end, "") }),
			W.Label(scope, { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = Theme.inkMuted, TextSize = 15, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
				Text = field(function(v) return v.stats end, "") }),
			W.Button(scope, { LayoutOrder = 3, Visible = field(function(v) return v.buy ~= nil end, false),
				primary = true, Text = field(function(v) return v.buy or "" end, ""), onClick = act(props.onBuy) }),
			W.Button(scope, { LayoutOrder = 4, Visible = field(function(v) return v.equip end, false),
				Text = T("Shop_Equip"), onClick = act(props.onEquip) }),
			W.Button(scope, { LayoutOrder = 5, Text = T("Shop_Close"), onClick = function() item:set(nil) end }),
		},
	})
end
