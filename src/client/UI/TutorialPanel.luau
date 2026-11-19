-- Tutorial panel: the current step's short hint plus a Skip button (top-centre, under the messages), and a
-- Highlight + bouncing arrow on the nearest map part tagged with the step's target (SpawnDock / SellNPC / BaitShop).
-- Display only: the step comes from Sync data (Player Profile `tutorialStep`); hidden for good once done.
-- props = { data: Value(profile data | nil), onSkip() }
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Fusion = require(RS:WaitForChild("Packages"):WaitForChild("Fusion"))
local Tutorial = require(RS:WaitForChild("Tutorial"))
local T = require(script.Parent:WaitForChild("T"))
local W = require(script.Parent:WaitForChild("Widgets"))
local Children = Fusion.Children

local GOLD = Color3.fromRGB(255, 210, 60)

local function nearest(tag)
	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local best, bestDist = nil, math.huge
	for _, inst in CollectionService:GetTagged(tag) do
		local part = if inst:IsA("Model") then inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true) else inst
		if part and part:IsA("BasePart") then
			local dist = if root then (part.Position - root.Position).Magnitude else 0
			if dist < bestDist then best, bestDist = part, dist end
		end
	end
	return best
end

return function(scope, props)
	local hint = scope:Computed(function(use)
		local d = use(props.data)
		return d and Tutorial.hint(d.tutorialStep)
	end)

	-- world pointer: re-aimed at the nearest target on every Sync (a new data table re-runs the hint) and respawn
	local highlight = scope:New "Highlight" { FillColor = GOLD, FillTransparency = 0.6, OutlineColor = GOLD,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }
	local arrow = scope:New "BillboardGui" {
		Size = UDim2.fromOffset(60, 60), AlwaysOnTop = true, StudsOffset = Vector3.new(0, 6, 0),
		[Children] = W.Label(scope, { Size = UDim2.fromScale(1, 1), Text = "▼", TextSize = 48, TextColor3 = GOLD,
			TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.2 }),
	}
	local function aim()
		local h = Fusion.peek(hint)
		local part = h and nearest(h.target)
		highlight.Adornee, highlight.Parent = part, part
		arrow.Adornee, arrow.Parent = part, part
	end
	scope:Observer(hint):onBind(aim)
	table.insert(scope, Players.LocalPlayer.CharacterAdded:Connect(function() task.defer(aim) end))
	table.insert(scope, RunService.RenderStepped:Connect(function()
		arrow.StudsOffset = Vector3.new(0, 6 + math.sin(os.clock() * 4) * 0.6, 0)
	end))

	return W.Panel(scope, {
		Name = "Tutorial",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 56),
		Size = UDim2.new(0.6, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = scope:Computed(function(use) return use(hint) ~= nil end),
		[Children] = {
			scope:New "UISizeConstraint" { MaxSize = Vector2.new(440, math.huge) },
			scope:New "UIPadding" { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) },
			scope:New "UIListLayout" { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center },
			W.Label(scope, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true,
				TextSize = 16,
				TextColor3 = GOLD,
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = scope:Computed(function(use)
					local h = use(hint)
					return if h then T(h.text) else ""
				end),
			}),
			W.Button(scope, { Size = UDim2.fromOffset(140, 32), Text = T("Tut_Skip"), BackgroundColor3 = Color3.fromRGB(80, 80, 95),
				onClick = props.onSkip }),
		},
	})
end
