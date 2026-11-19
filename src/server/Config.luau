-- Config.luau
-- Pasar Brainrot: every tuning number for the game lives in this one module,
-- so balancing never means hunting through the services. All money is in
-- dollars, all distances in studs, all times in seconds.

local Config = {}

-- Starting money, and the money a rebirth leaves you with.
Config.StartCash = 250
Config.RebirthCash = 150

-- Walk speed with no upgrades bought.
Config.DefaultWalkSpeed = 16

-- Each rebirth level multiplies income by +25%; each income-upgrade level
-- adds another +25%. The two bonuses multiply together.
Config.RebirthBonus = 0.25
Config.IncomeBonus = 0.25

-- Rarities, cheapest first. Order decides the ladder; Color tints the
-- character's glow ring and its name label.
Config.Rarities = {
	Common = { Order = 1, Color = Color3.fromRGB(158, 227, 125) },
	Rare = { Order = 2, Color = Color3.fromRGB(76, 201, 240) },
	Epic = { Order = 3, Color = Color3.fromRGB(157, 78, 221) },
	Legendary = { Order = 4, Color = Color3.fromRGB(255, 183, 3) },
	Mythic = { Order = 5, Color = Color3.fromRGB(255, 77, 109) },
}

-- The nine snack characters. Weight is the relative spawn chance; Height is
-- the nominal body height in studs (placement always uses the model's real
-- measured bounding box instead).
Config.Characters = {
	{ Key = "bakso", Name = "Bakso Berlari", Rarity = "Common", Price = 50, Rate = 5, Weight = 25, Height = 3.1, Color = Color3.fromRGB(225, 170, 110) },
	{ Key = "teh", Name = "Es Teh Manis Terbang", Rarity = "Common", Price = 100, Rate = 8, Weight = 20, Height = 3.6, Color = Color3.fromRGB(230, 160, 50) },
	{ Key = "gorengan", Name = "Gorengan Galak", Rarity = "Rare", Price = 400, Rate = 20, Weight = 16, Height = 3.6, Color = Color3.fromRGB(240, 190, 60) },
	{ Key = "kucing", Name = "Kucing Oren Ngamuk", Rarity = "Rare", Price = 800, Rate = 35, Weight = 12, Height = 3.9, Color = Color3.fromRGB(255, 140, 40) },
	{ Key = "geprek", Name = "Ayam Geprek Terbang", Rarity = "Epic", Price = 2000, Rate = 60, Weight = 10, Height = 4.2, Color = Color3.fromRGB(245, 220, 180) },
	{ Key = "durian", Name = "Durian Meledak", Rarity = "Epic", Price = 4000, Rate = 100, Weight = 7, Height = 4.5, Color = Color3.fromRGB(140, 225, 95) },
	{ Key = "kopi", Name = "Kopi Tubruk Raksasa", Rarity = "Legendary", Price = 10000, Rate = 180, Weight = 5, Height = 5.0, Color = Color3.fromRGB(185, 130, 85) },
	{ Key = "gerobak", Name = "Gerobak Bakso Terbang", Rarity = "Legendary", Price = 20000, Rate = 300, Weight = 3, Height = 5.6, Color = Color3.fromRGB(215, 110, 85) },
	{ Key = "padang", Name = "Nasi Padang Sejagat", Rarity = "Mythic", Price = 50000, Rate = 500, Weight = 2, Height = 5.9, Color = Color3.fromRGB(255, 240, 200) },
}

-- The conveyor belt: brainrots walk from StartX to EndX along z = 0, resting
-- on the belt top. Preseed puts four of them on the belt when the server
-- starts so the market is never empty.
Config.Belt = {
	StartX = -72,
	EndX = 72,
	TopY = 3,
	Speed = 3.5,
	SpawnEvery = 5,
	MaxOnBelt = 8,
	Preseed = { -72, -45, -18, 9 },
}

-- The six lapak (bases), two rows of three north and south of the belt.
-- Each platform is 26 wide (x) by 20 deep (z).
Config.Bases = {
	{ X = -55, Z = -28, Color = Color3.fromRGB(255, 183, 3) },
	{ X = 0, Z = -28, Color = Color3.fromRGB(76, 201, 240) },
	{ X = 55, Z = -28, Color = Color3.fromRGB(255, 77, 109) },
	{ X = -55, Z = 28, Color = Color3.fromRGB(120, 220, 110) },
	{ X = 0, Z = 28, Color = Color3.fromRGB(255, 140, 40) },
	{ X = 55, Z = 28, Color = Color3.fromRGB(157, 78, 221) },
}

-- Six pedestals per lapak, two rows of three, as offsets from the lapak centre.
Config.PedestalOffsets = {
	{ X = -7, Z = -3.5 },
	{ X = 0, Z = -3.5 },
	{ X = 7, Z = -3.5 },
	{ X = -7, Z = 3.5 },
	{ X = 0, Z = 3.5 },
	{ X = 7, Z = 3.5 },
}

-- The Gerobak Tsunami: first wave 75 seconds in, then every 90 seconds.
Config.Wave = {
	FirstAt = 75,
	Every = 90,
	WarnSecs = 10,
	SweepSecs = 12,
}

-- Kunci Lapak: 30 seconds locked, then a 90-second cooldown.
Config.Lock = {
	Duration = 30,
	Cooldown = 90,
}

-- Rebirth ladder: the lifetime earnings each level needs, and the title it grants.
Config.Rebirths = {
	{ Need = 25000, Title = "Pedagang Keliling" },
	{ Need = 150000, Title = "Juragan Pasar" },
	{ Need = 750000, Title = "Sultan Brainrot" },
	{ Need = 3000000, Title = "Legenda Pasar Malam" },
}

-- Upgrades. Speeds are the walk speeds each speed level grants.
Config.Upgrades = {
	speed = { Name = "Sepatu Kilat", Desc = "Lari lebih cepat", Costs = { 500, 2000, 6000 }, Speeds = { 20, 24, 28 } },
	carry = { Name = "Tangan Kedua", Desc = "Bawa 2 brainrot sekaligus", Costs = { 2500 } },
	income = { Name = "Timbangan Emas", Desc = "+25% $/detik per level", Costs = { 1000, 4000, 12000 } },
}

-- The colour a rarity name maps to (white when unknown, so a typo never
-- crashes the game).
function Config.rarityColor(rarityName)
	local entry = Config.Rarities[rarityName]
	if entry then
		return entry.Color
	end
	return Color3.fromRGB(255, 255, 255)
end

-- Find a character definition by its internal key.
function Config.findCharacter(key)
	for _, character in ipairs(Config.Characters) do
		if character.Key == key then
			return character
		end
	end
	return nil
end

return Config
