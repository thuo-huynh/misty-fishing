-- One message line at the top of the screen (above the water), cleared after a few seconds.
-- Returns (label, show(text, color?)).
local W = require(script.Parent:WaitForChild("Widgets"))

local SHOW_FOR = 3.5

return function(scope)
	local text, color = scope:Value(""), scope:Value(Color3.new(1, 1, 1))
	local token = 0
	local function show(t: string, c: Color3?)
		token += 1
		local mine = token
		text:set(t)
		color:set(c or Color3.new(1, 1, 1))
		task.delay(SHOW_FOR, function()
			if token == mine then text:set("") end
		end)
	end
	local label = W.Label(scope, {
		Name = "Message",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0.6, 0, 0, 40),
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.3,
		Text = text,
		TextColor3 = color,
	})
	return label, show
end
