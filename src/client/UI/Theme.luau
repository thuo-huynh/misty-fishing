-- Design tokens of the Misty Fishing design system (tokens.json), as Roblox values.
-- Change the look here, not in the UI modules. Alpha values are BackgroundTransparency (1 - CSS alpha).
local hex = Color3.fromHex

return {
	-- surfaces
	panel = hex("0c1214"), panelAlpha = 0.26, -- HUD glass: the world shows through
	panelSolid = hex("0e1416"), panelSolidAlpha = 0.04, -- modal panels
	line = Color3.new(1, 1, 1), lineAlpha = 0.9, lineStrongAlpha = 0.84, -- 1px borders
	track = Color3.new(1, 1, 1), trackAlpha = 0.9, -- empty part of bars

	-- text
	ink = hex("e8ecea"),
	inkMuted = hex("a9b5b2"),
	inkFaint = hex("8d9996"),

	-- accent and state
	amber = hex("e8b45a"), amberInk = hex("1a140a"),
	safe = hex("6cc4b4"),
	danger = hex("e8765a"),

	-- shape and space (px)
	radius = { sm = 7, md = 10, lg = 16 },
	space = { 4, 8, 12, 16, 20, 26 },
	touchMin = 44,

	-- type: Barlow Condensed and Inter are not Roblox fonts; Roboto Condensed and Builder Sans stand in
	display = Font.new("rbxasset://fonts/families/RobotoCondensed.json", Enum.FontWeight.Bold),
	numeral = Font.new("rbxasset://fonts/families/RobotoCondensed.json", Enum.FontWeight.SemiBold),
	sans = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular),
	sansBold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold),
}
