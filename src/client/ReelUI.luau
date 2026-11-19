-- Reel UI: Tension bar (green / yellow / red) and distance to the fish while reeling.
-- Display only: values come from the server (Reel remote); the bar eases toward them between ticks.
-- shortcut: plain Instances; #14 restyles it with Fusion.
local RunService = game:GetService("RunService")

local GREEN, YELLOW, RED = Color3.fromRGB(70, 220, 110), Color3.fromRGB(240, 200, 60), Color3.fromRGB(230, 70, 60)
local SMOOTH = 12 -- 1/s; how fast the shown values catch up with the server

local ReelUI = {}

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

-- Builds the panel inside `gui`. Returns { show(), hide(), set(tension, distance) }.
function ReelUI.mount(gui)
	local frame = make("Frame", { Size = UDim2.fromOffset(420, 64), Position = UDim2.new(0.5, -210, 1, -170),
		BackgroundColor3 = Color3.fromRGB(15, 25, 40), BackgroundTransparency = 0.2, Visible = false }, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, frame)
	make("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, -22), BackgroundTransparency = 1,
		Text = "Hold click / touch / Space to reel. Release before the line snaps!", TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.4, Font = Enum.Font.GothamBold, TextSize = 14 }, frame)
	local track = make("Frame", { Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 8),
		BackgroundColor3 = Color3.fromRGB(40, 50, 65) }, frame)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, track)
	local bar = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GREEN }, track)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, bar)
	local distLabel = make("TextLabel", { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 38),
		BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 15,
		Text = "" }, frame)

	local target, shown = { tension = 0, distance = 0 }, { tension = 0, distance = 0 }
	local conn

	local function render(dt)
		local a = 1 - math.exp(-SMOOTH * dt)
		shown.tension += (target.tension - shown.tension) * a
		shown.distance += (target.distance - shown.distance) * a
		local t = math.clamp(shown.tension, 0, 1)
		bar.Size = UDim2.fromScale(t, 1)
		bar.BackgroundColor3 = if t < 0.5 then GREEN elseif t < 0.8 then YELLOW else RED
		distLabel.Text = string.format("Fish: %.1f studs away", math.max(0, shown.distance))
	end

	local ui = {}
	function ui.set(tension, distance)
		if typeof(tension) ~= "number" or typeof(distance) ~= "number" then return end
		if target.distance == 0 then shown.distance = distance end -- first tick: no slide in from 0
		target.tension, target.distance = tension, distance
	end
	function ui.show()
		target.tension, target.distance, shown.tension, shown.distance = 0, 0, 0, 0
		render(0)
		frame.Visible = true
		conn = conn or RunService.RenderStepped:Connect(render)
	end
	function ui.hide()
		frame.Visible = false
		if conn then conn:Disconnect() conn = nil end
	end
	return ui
end

return ReelUI
