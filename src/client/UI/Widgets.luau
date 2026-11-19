-- Shared look for the Fusion UI: Panel, Label, Button. Each takes (scope, props); props override the defaults.
local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local Children, OnEvent = Fusion.Children, Fusion.OnEvent

local Widgets = {}

local function build(scope, class, defaults, props)
	for k, v in props do defaults[k] = v end
	return scope:New(class)(defaults)
end

-- props[Children] are added after the panel's own UICorner
function Widgets.Panel(scope, props)
	props[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 10) }, props[Children] }
	return build(scope, "Frame", { BackgroundColor3 = Color3.fromRGB(20, 30, 45), BackgroundTransparency = 0.15 }, props)
end

function Widgets.Label(scope, props)
	return build(scope, "TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, props)
end

-- props.onClick: called on Activated (mouse, touch, gamepad)
function Widgets.Button(scope, props)
	local onClick = props.onClick
	props.onClick = nil
	return build(scope, "TextButton", {
		Size = UDim2.new(1, 0, 0, 36), -- 36px: still a comfortable touch target
		BackgroundColor3 = Color3.fromRGB(50, 90, 130),
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		[OnEvent "Activated"] = onClick,
		[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 8) } },
	}, props)
end

return Widgets
