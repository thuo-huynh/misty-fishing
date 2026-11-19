-- The round action button, bottom-right (thumb reach on phones). Its label follows the cast phase.
-- Design system: glass with an amber ring while idle; amber fill on a bite and while reeling (held, larger).
-- On touch screens it sits above Roblox's jump button. Reeling is a hold: the client's input handler
-- already treats any press during "reeling" as holding, so the button only acts in the other phases.
-- props = { phase: Value("idle" | "casting" | "waiting" | "bite" | "reeling"), touch: boolean, keyboard: boolean, onPress() }
local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local T = require(script.Parent:WaitForChild("T"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Children, OnEvent = Fusion.Children, Fusion.OnEvent

local KEYS = { idle = "Action_Cast", casting = "Action_Cast", waiting = "Action_ReelIn", bite = "Action_Hook", reeling = "Action_Reel" }
local HOT = { bite = true, reeling = true } -- phases that need the player now

return function(scope, props)
	local phase = props.phase
	local hot = scope:Computed(function(use) return HOT[use(phase)] == true end)
	local size = scope:Computed(function(use) return if use(phase) == "reeling" then 132 else 120 end)
	return scope:New "TextButton" {
		Name = "ActionButton",
		AnchorPoint = Vector2.new(1, 1),
		Position = if props.touch then UDim2.new(1, -24, 1, -170) else UDim2.new(1, -24, 1, -24),
		Size = scope:Computed(function(use) return UDim2.fromOffset(use(size), use(size)) end),
		BackgroundColor3 = scope:Computed(function(use) return if use(hot) then Theme.amber else Theme.panel end),
		BackgroundTransparency = scope:Computed(function(use) return if use(hot) then 0 else Theme.panelAlpha end),
		TextColor3 = scope:Computed(function(use) return if use(hot) then Theme.amberInk else Theme.ink end),
		FontFace = Theme.display,
		TextSize = 24,
		TextWrapped = true,
		RichText = true,
		Text = scope:Computed(function(use)
			local p = use(phase)
			local spaceHint = props.keyboard and p ~= "idle" and p ~= "casting"
			return T(KEYS[p]) .. (if spaceHint then `\n<font size="13">Space</font>` else "")
		end),
		[OnEvent "Activated"] = props.onPress,
		[Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0.5, 0) },
			scope:New "UIStroke" { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 2, Color = Theme.amber },
		},
	}
end
