-- HUD (design system: "Layout of the fishing screen"). Left column: Coins and Bag, then the Tackle rows
-- (tap cycles to the next usable one) and Collection; top-centre: a clock chip. The Tackle panel sits left,
-- not right as in the design, because Roblox's player list takes the top-right corner.
-- props = { data: Value(Profile data | nil), keyboard: boolean, onCycle(kind), onBag(), onCollection() }
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local Content = require(RS:WaitForChild("Content"))
local T = require(script.Parent:WaitForChild("T"))
local W = require(script.Parent:WaitForChild("Widgets"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Children = Fusion.Children

local MUTED = "#" .. Theme.inkMuted:ToHex()
local AMBER = "#" .. Theme.amber:ToHex()

local function name(kind, id) return T(`{kind}_{id}`, nil, Content[kind][id].name) end

return function(scope, props)
	local data = props.data
	local hint = function(key) return if props.keyboard then `  <font color="{MUTED}">[{key}]</font>` else "" end

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

	-- a number with its capitalised label above it
	local function readout(order, caption, value, color)
		return scope:New "Frame" {
			LayoutOrder = order, BackgroundTransparency = 1, Size = UDim2.new(0.5, -4, 1, 0),
			[Children] = {
				W.Caption(scope, { Text = caption }),
				W.Label(scope, { Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 28), FontFace = Theme.numeral,
					TextSize = 26, TextColor3 = color or Theme.ink, Text = value }),
			},
		}
	end

	-- one Tackle slot: muted slot name, then the item; tap cycles
	local function slot(order, labelKey, kind, valueFn, key)
		return W.Button(scope, {
			LayoutOrder = order, Size = UDim2.new(1, 0, 0, 40), RichText = true, TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Theme.sans, TextSize = 14,
			Text = text(function(d) return `<font color="{MUTED}">{T(labelKey)}</font>   {valueFn(d)}` .. (if key then hint(key) else "") end),
			onClick = function() props.onCycle(kind) end,
			[Children] = scope:New "UIPadding" { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) },
		})
	end

	local panel = W.Panel(scope, {
		Name = "Hud",
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(240, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Children] = {
			scope:New "UIListLayout" { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder },
			scope:New "UIPadding" {
				PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
				PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14),
			},
			scope:New "Frame" {
				LayoutOrder = 1, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46),
				[Children] = {
					scope:New "UIListLayout" { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
						SortOrder = Enum.SortOrder.LayoutOrder },
					readout(1, T("Hud_Coins"), text(function(d) return tostring(d.coins) end), Theme.amber),
					-- the Bag readout is also the button that opens the Bag
					scope:New "TextButton" {
						LayoutOrder = 2, BackgroundTransparency = 1, Size = UDim2.new(0.5, -4, 1, 0), Text = "",
						[Fusion.OnEvent "Activated"] = props.onBag,
						[Children] = readout(1, T("Hud_Bag") .. (if props.keyboard then "  [V]" else ""),
							text(function(d) return `{#d.bag} / {Content.balance.bagSize}` end)),
					},
				},
			},
			W.Caption(scope, { LayoutOrder = 2, Text = T("Hud_Tackle") }),
			slot(3, "Hud_Rod", "rods", function(d) return name("rods", d.equipped.rod) end),
			slot(4, "Hud_Line", "lines", function(d) return name("lines", d.equipped.line) end),
			slot(5, "Hud_Bait", "baits", function(d)
				local id = d.equipped.bait
				if Content.baits[id].price == 0 then return name("baits", id) end
				return `{name("baits", id)} <font color="{AMBER}">x{d.baits[id] or 0}</font>`
			end, "B"),
			W.Button(scope, { LayoutOrder = 6, RichText = true, Text = T("Hud_Collection") .. hint("C"), onClick = props.onCollection }),
		},
	})

	local clockChip = W.Panel(scope, {
		Name = "Clock",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		[Children] = {
			scope:New "UIPadding" { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) },
			W.Label(scope, { Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, FontFace = Theme.numeral,
				TextSize = 18, Text = clock }),
		},
	})

	return scope:New "Folder" { Name = "HudRoot", [Children] = { panel, clockChip } }
end
