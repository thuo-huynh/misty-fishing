-- Reel bar: line Tension and distance to the fish while reeling, bottom-centre (left of the action button).
-- Design system "TensionGauge", drawn straight: zones safe 0–60%, amber 60–85%, danger 85–100% behind the fill,
-- the percentage in the zone's colour. Display only: values come from the server (Reel remote); the bar eases
-- toward them between ticks. Returns (frame, { show(), hide(), set(tension, distance) }).
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local T = require(script.Parent:WaitForChild("T"))
local W = require(script.Parent:WaitForChild("Widgets"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Children = Fusion.Children

local ZONES = { { 0, 0.6, Theme.safe }, { 0.6, 0.85, Theme.amber }, { 0.85, 1, Theme.danger } }
local SMOOTH = 12 -- 1/s; how fast the shown values catch up with the server

local function zoneColor(t)
	for _, z in ZONES do
		if t < z[2] then return z[3] end
	end
	return Theme.danger
end

return function(scope)
	local visible = scope:Value(false)
	local tension, distance = scope:Value(0), scope:Value(0) -- shown (smoothed) values
	local target = { tension = 0, distance = 0 }
	local conn

	local function render(dt)
		local a = 1 - math.exp(-SMOOTH * dt)
		tension:set(Fusion.peek(tension) + (target.tension - Fusion.peek(tension)) * a)
		distance:set(Fusion.peek(distance) + (target.distance - Fusion.peek(distance)) * a)
	end

	local zoneBands = {}
	for _, z in ZONES do
		table.insert(zoneBands, scope:New "Frame" {
			Position = UDim2.fromScale(z[1], 0), Size = UDim2.fromScale(z[2] - z[1], 1),
			BackgroundColor3 = z[3], BackgroundTransparency = 0.75, BorderSizePixel = 0,
		})
	end

	local frame = W.Panel(scope, {
		Name = "ReelBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -96), -- above the Roblox hotbar
		Size = UDim2.new(0.55, 0, 0, 92),
		Visible = visible,
		[Children] = {
			scope:New "UISizeConstraint" { MaxSize = Vector2.new(460, 92) },
			W.Label(scope, {
				Position = UDim2.fromOffset(0, -28), Size = UDim2.new(1, 0, 0, 22), TextSize = 15, TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.5, Text = T("Reel_Hint"),
			}),
			W.Caption(scope, { Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 14), Text = T("Reel_Tension") }),
			W.Label(scope, {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 6), Size = UDim2.fromOffset(80, 26),
				TextXAlignment = Enum.TextXAlignment.Right, FontFace = Theme.numeral, TextSize = 26,
				TextColor3 = scope:Computed(function(use) return zoneColor(use(tension)) end),
				Text = scope:Computed(function(use) return `{math.floor(math.clamp(use(tension), 0, 1) * 100 + 0.5)}%` end),
			}),
			-- the bar: zone bands, then the fill in the current zone's colour
			scope:New "Frame" {
				Position = UDim2.fromOffset(16, 36), Size = UDim2.new(1, -32, 0, 14),
				BackgroundColor3 = Theme.track, BackgroundTransparency = Theme.trackAlpha, ClipsDescendants = true,
				[Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, Theme.radius.sm) },
					zoneBands,
					scope:New "Frame" {
						Size = scope:Computed(function(use) return UDim2.fromScale(math.clamp(use(tension), 0, 1), 1) end),
						BackgroundColor3 = scope:Computed(function(use) return zoneColor(use(tension)) end),
						BorderSizePixel = 0,
					},
				},
			},
			W.Label(scope, {
				Position = UDim2.fromOffset(16, 58), Size = UDim2.new(1, -32, 0, 24), FontFace = Theme.numeral, TextSize = 20,
				Text = scope:Computed(function(use)
					return T("Reel_Distance", { studs = string.format("%.1f", math.max(0, use(distance))) })
				end),
			}),
		},
	})

	local ui = {}
	function ui.set(t, d)
		if typeof(t) ~= "number" or typeof(d) ~= "number" then return end
		if target.distance == 0 then distance:set(d) end -- first tick: no slide in from 0
		target.tension, target.distance = t, d
	end
	function ui.show()
		target.tension, target.distance = 0, 0
		tension:set(0)
		distance:set(0)
		visible:set(true)
		conn = conn or RunService.RenderStepped:Connect(render)
	end
	function ui.hide()
		visible:set(false)
		if conn then conn:Disconnect() conn = nil end
	end
	return frame, ui
end
