-- Text: turns a LocalizationTable's entries into T(key, args?, fallback?) -> display string.
-- Picks the player's locale ("vi-vn"), then its language ("vi"), then English, then Source.
-- Placeholders are {name}; a missing arg stays as "{name}" so the gap is visible.
-- Pure (no Roblox APIs) so Lune can test it; the client passes LocalizationService's UI table.
local Text = {}

function Text.new(entries, locale: string)
	local lang = string.match(locale, "^%a+") or "en"
	local byKey = {}
	for _, e in entries do
		local v = e.Values or {}
		local s = v[locale] or v[lang] or v.en
		byKey[e.Key] = if s and s ~= "" then s else e.Source
	end
	return function(key: string, args: { [string]: any }?, fallback: string?): string
		local s = byKey[key] or fallback or key
		return (string.gsub(s, "{(%w+)}", function(name)
			local a = args and args[name]
			return if a ~= nil then tostring(a) else nil
		end))
	end
end

return Text
