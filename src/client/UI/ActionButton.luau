-- The big primary button, bottom-right (thumb reach on phones). Its label follows the cast phase.
-- On touch screens it sits above Roblox's jump button. Reeling is a hold: the client's input handler
-- already treats any press during "reeling" as holding, so the button only acts in the other phases.
-- props = { phase: Value("idle" | "casting" | "waiting" | "bite" | "reeling"), touch: boolean, keyboard: boolean, onPress() }
local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local T = require(script.Parent:WaitForChild("T"))
local W = require(script.Parent:WaitForChild("Widgets"))
local Children = Fusion.Children

local KEYS = { idle = "Action_Cast", casting = "Action_Cast", waiting = "Action_ReelIn", bite = "Action_Hook", reeling = "Action_Reel" }
local COLORS = { bite = Color3.fromRGB(230, 170, 30), reeling = Color3.fromRGB(60, 170, 90) }

return function(scope, props)
	return W.Button(scope, {
		Name = "ActionButton",
		AnchorPoint = Vector2.new(1, 1),
		Position = if props.touch then UDim2.new(1, -24, 1, -170) else UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(120, 120),
		TextSize = 22,
		TextWrapped = true,
		BackgroundColor3 = scope:Computed(function(use) return COLORS[use(props.phase)] or Color3.fromRGB(40, 110, 190) end),
		Text = scope:Computed(function(use)
			local phase = use(props.phase)
			local spaceHint = props.keyboard and phase ~= "idle" and phase ~= "casting"
			return T(KEYS[phase]) .. (if spaceHint then "\n[Space]" else "")
		end),
		onClick = props.onPress,
		[Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0.5, 0) },
			scope:New "UIStroke" { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 3, Color = Color3.new(1, 1, 1), Transparency = 0.4 },
		},
	})
end
