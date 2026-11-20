-- Pasar Brainrot: every tuning number lives here, so the rest of the game reads
-- behaviour from data instead of scattering magic numbers through the services.
local Config = {}

Config.START_CASH = 250
Config.REBIRTH_CASH = 150
Config.DEFAULT_WALK_SPEED = 16

Config.RARITIES = {
	Common = { Color = Color3.fromRGB(158, 227, 125), Order = 1 },
	Rare = { Color = Color3.fromRGB(76, 201, 240), Order = 2 },
	Epic = { Color = Color3.fromRGB(157, 78, 221), Order = 3 },
	Legendary = { Color = Color3.fromRGB(255, 183, 3), Order = 4 },
	Mythic = { Color = Color3.fromRGB(255, 77, 109), Order = 5 },
}

-- Key, display name, rarity, price, income per second, spawn weight, body height, body colour.
Config.CHARACTERS = {
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

Config.BELT = {
	StartX = -72,
	EndX = 72,
	Z = 0,
	TopY = 3,
	Speed = 3.5,
	SpawnInterval = 5,
	MaxOnBelt = 8,
}

-- Six lapak, two rows of three, north and south of the belt.
Config.BASES = {
	{ X = -55, Z = -28, Color = Color3.fromRGB(255, 183, 3) },
	{ X = 0, Z = -28, Color = Color3.fromRGB(76, 201, 240) },
	{ X = 55, Z = -28, Color = Color3.fromRGB(255, 77, 109) },
	{ X = -55, Z = 28, Color = Color3.fromRGB(120, 220, 110) },
	{ X = 0, Z = 28, Color = Color3.fromRGB(255, 140, 40) },
	{ X = 55, Z = 28, Color = Color3.fromRGB(157, 78, 221) },
}
Config.BASE_WIDTH = 26
Config.BASE_DEPTH = 20

-- Pedestal offsets from the lapak centre, two rows of three.
Config.PEDESTAL_OFFSETS = {
	{ X = -7, Z = -3.5 },
	{ X = 0, Z = -3.5 },
	{ X = 7, Z = -3.5 },
	{ X = -7, Z = 3.5 },
	{ X = 0, Z = 3.5 },
	{ X = 7, Z = 3.5 },
}

Config.WAVE = { FirstDelay = 75, Interval = 90, WarnTime = 10, SweepTime = 12 }
Config.LOCK = { Duration = 30, Cooldown = 90 }

Config.REBIRTHS = {
	{ Need = 25000, Title = "Pedagang Keliling" },
	{ Need = 150000, Title = "Juragan Pasar" },
	{ Need = 750000, Title = "Sultan Brainrot" },
	{ Need = 3000000, Title = "Legenda Pasar Malam" },
}
Config.REBIRTH_BONUS = 0.25
Config.INCOME_BONUS = 0.25

Config.UPGRADES = {
	speed = { Name = "Sepatu Kilat", Desc = "Lari lebih cepat", Costs = { 500, 2000, 6000 }, Speeds = { 20, 24, 28 } },
	carry = { Name = "Tangan Kedua", Desc = "Bawa 2 brainrot sekaligus", Costs = { 2500 } },
	income = { Name = "Timbangan Emas", Desc = "+25% $/detik per level", Costs = { 1000, 4000, 12000 } },
}

return Config
