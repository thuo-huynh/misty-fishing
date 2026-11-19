-- Bag UI: toggleable list of the Catches in the bag (Species, kg, sell price) and the total the market pays.
-- Display only: data comes from the server Sync; prices use the shared rule (Rules/Catch.sellPrice).
-- shortcut: plain Instances; #14 restyles it with Fusion.
local RS = game:GetService("ReplicatedStorage")

local Content = require(RS:WaitForChild("Content"))
local Catch = require(RS:WaitForChild("Rules"):WaitForChild("Catch"))

local BagUI = {}

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

-- Builds a "Bag (V)" button and the panel inside `gui`. Returns { toggle(), set(profileData) }.
function BagUI.mount(gui)
	local button = make("TextButton", { Size = UDim2.fromOffset(230, 30), Position = UDim2.fromOffset(12, 262),
		BackgroundColor3 = Color3.fromRGB(60, 120, 90), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
		TextSize = 15, Text = "Bag (V)" }, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, button)

	local panel = make("Frame", { Size = UDim2.new(0, 380, 0.7, 0), Position = UDim2.new(0.5, -190, 0.15, 0),
		BackgroundColor3 = Color3.fromRGB(20, 30, 45), Visible = false }, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, panel)
	local title = make("TextLabel", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "Bag",
		TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 20 }, panel)
	local list = make("ScrollingFrame", { Size = UDim2.new(1, -16, 1, -44), Position = UDim2.fromOffset(8, 38),
		BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 6 }, panel)
	make("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local data = nil

	local function render()
		for _, c in list:GetChildren() do
			if c:IsA("TextLabel") then c:Destroy() end
		end
		if not data then return end
		local total = 0
		for i, c in data.bag do
			local species = Content.species[c.species]
			local price = if species then Catch.sellPrice(species, c.kg) else 0
			if species and not c.kept then total += price end
			make("TextLabel", { Size = UDim2.new(1, -8, 0, 22), BackgroundTransparency = 1, LayoutOrder = i,
				TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 14,
				TextColor3 = if species then Color3.fromRGB(table.unpack(Content.rarities[species.rarity].color)) else Color3.fromRGB(110, 110, 110),
				Text = string.format("%s  %.2f kg  %d coins%s", if species then species.name else "???", c.kg, price, if c.kept then "  (kept)" else "") }, list)
		end
		title.Text = string.format("Bag %d/%d  -  sells for %d coins", #data.bag, Content.balance.bagSize, total)
	end

	local ui = {}
	function ui.toggle()
		panel.Visible = not panel.Visible
		if panel.Visible then render() end
	end
	function ui.set(d)
		data = d
		if panel.Visible then render() end
	end
	button.Activated:Connect(ui.toggle)
	return ui
end

return BagUI
