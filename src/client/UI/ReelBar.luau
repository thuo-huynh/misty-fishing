-- Reel bar: Tension (green / yellow / red) and distance to the fish while reeling, bottom-centre
-- (left of the action button). Display only: values come from the server (Reel remote); the bar eases
-- toward them between ticks. Returns (frame, { show(), hide(), set(tension, distance) }).
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local T = require(script.Parent:WaitForChild("T"))
local W = require(script.Parent:WaitForChild("Widgets"))
local Children = Fusion.Children

local GREEN, YELLOW, RED = Color3.fromRGB(70, 220, 110), Color3.fromRGB(240, 200, 60), Color3.fromRGB(230, 70, 60)
local SMOOTH = 12 -- 1/s; how fast the shown values catch up with the server

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

	local frame = W.Panel(scope, {
		Name = "ReelBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -96), -- above the Roblox hotbar
		Size = UDim2.new(0.5, 0, 0, 64),
		BackgroundTransparency = 0.2,
		Visible = visible,
		[Children] = {
			scope:New "UISizeConstraint" { MaxSize = Vector2.new(420, 64) },
			W.Label(scope, {
				Position = UDim2.fromOffset(0, -24), TextSize = 14, TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4, Text = T("Reel_Hint"),
			}),
			scope:New "Frame" {
				Size = UDim2.new(1, -20, 0, 24),
				Position = UDim2.fromOffset(10, 8),
				BackgroundColor3 = Color3.fromRGB(40, 50, 65),
				[Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
					scope:New "Frame" {
						Size = scope:Computed(function(use) return UDim2.fromScale(math.clamp(use(tension), 0, 1), 1) end),
						BackgroundColor3 = scope:Computed(function(use)
							local t = use(tension)
							return if t < 0.5 then GREEN elseif t < 0.8 then YELLOW else RED
						end),
						[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 6) } },
					},
				},
			},
			W.Label(scope, {
				Size = UDim2.new(1, -20, 0, 20),
				Position = UDim2.fromOffset(10, 38),
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
