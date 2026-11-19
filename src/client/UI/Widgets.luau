-- Shared look for the Fusion UI (design system: Theme.luau). Each takes (scope, props); props override the defaults.
-- Panel { solid? } · Label · Caption (small capitalised label) · Button { primary? }
local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Children, OnEvent = Fusion.Children, Fusion.OnEvent

local Widgets = {}

local function build(scope, class, defaults, props, own)
	local extra = props[Children]
	for k, v in props do defaults[k] = v end
	defaults[Children] = { own, extra } -- the widget's own corner/stroke, then the caller's children
	return scope:New(class)(defaults)
end

local function stroke(scope, alpha)
	return scope:New "UIStroke" { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.line, Transparency = alpha, Thickness = 1 }
end

-- props.solid: a modal panel (shop, Collection, Bag) instead of HUD glass
function Widgets.Panel(scope, props)
	local solid = props.solid
	props.solid = nil
	return build(scope, "Frame", {
		BackgroundColor3 = if solid then Theme.panelSolid else Theme.panel,
		BackgroundTransparency = if solid then Theme.panelSolidAlpha else Theme.panelAlpha,
	}, props, {
		scope:New "UICorner" { CornerRadius = UDim.new(0, if solid then Theme.radius.lg else Theme.radius.md) },
		stroke(scope, Theme.lineAlpha),
	})
end

function Widgets.Label(scope, props)
	return build(scope, "TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		TextColor3 = Theme.ink,
		FontFace = Theme.sans,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, props)
end

-- the small capitalised label above a number
function Widgets.Caption(scope, props)
	return build(scope, "TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		TextColor3 = Theme.inkMuted,
		FontFace = Theme.sansBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, props)
end

-- props.onClick: called on Activated (mouse, touch, gamepad). props.primary: the amber button, one per panel at most.
function Widgets.Button(scope, props)
	local onClick, primary = props.onClick, props.primary
	props.onClick, props.primary = nil, nil
	return build(scope, "TextButton", {
		Size = UDim2.new(1, 0, 0, Theme.touchMin),
		AutoButtonColor = true,
		BackgroundColor3 = if primary then Theme.amber else Theme.panel,
		BackgroundTransparency = if primary then 0 else Theme.panelAlpha,
		TextColor3 = if primary then Theme.amberInk else Theme.ink,
		FontFace = Theme.sansBold,
		TextSize = 15,
		[OnEvent "Activated"] = onClick,
	}, props, {
		scope:New "UICorner" { CornerRadius = UDim.new(0, Theme.radius.md) },
		if primary then nil else stroke(scope, Theme.lineStrongAlpha),
	})
end

return Widgets
