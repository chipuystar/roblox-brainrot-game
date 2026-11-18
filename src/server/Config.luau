-- Pasar Brainrot: single source of truth for tuning.
-- Characters, rarities, prices, income rates, rebirths, upgrades, world layout.
-- The server is authoritative; the client keeps a display-only copy of the
-- names and prices for its panels.

local Config = {}

Config.GAME_NAME = "Pasar Brainrot"
Config.START_CASH = 250
Config.BASE_CASH_AFTER_REBIRTH = 150

-- Rarity ladder, cheapest to rarest. The colour is used on labels, the
-- index panel and the pedestal trim.
Config.RARITIES = {
	Common = { color = Color3.fromRGB(158, 227, 125), order = 1 },
	Rare = { color = Color3.fromRGB(76, 201, 240), order = 2 },
	Epic = { color = Color3.fromRGB(157, 78, 221), order = 3 },
	Legendary = { color = Color3.fromRGB(255, 183, 3), order = 4 },
	Mythic = { color = Color3.fromRGB(255, 77, 109), order = 5 },
}

-- The cast: nine original Indonesian snack characters. price is what a
-- player pays on the conveyor, rate is $/second once placed on a lapak,
-- weight is the spawn chance, size is the model's body height in studs.
Config.CHARACTERS = {
	{ key = "bakso", name = "Bakso Berlari", rarity = "Common", price = 50, rate = 5, weight = 25, size = 3.1, color = Color3.fromRGB(225, 170, 110) },
	{ key = "teh", name = "Es Teh Manis Terbang", rarity = "Common", price = 100, rate = 8, weight = 20, size = 3.6, color = Color3.fromRGB(230, 160, 50) },
	{ key = "gorengan", name = "Gorengan Galak", rarity = "Rare", price = 400, rate = 20, weight = 16, size = 3.6, color = Color3.fromRGB(240, 190, 60) },
	{ key = "kucing", name = "Kucing Oren Ngamuk", rarity = "Rare", price = 800, rate = 35, weight = 12, size = 3.9, color = Color3.fromRGB(255, 140, 40) },
	{ key = "geprek", name = "Ayam Geprek Terbang", rarity = "Epic", price = 2000, rate = 60, weight = 10, size = 4.2, color = Color3.fromRGB(245, 220, 180) },
	{ key = "durian", name = "Durian Meledak", rarity = "Epic", price = 4000, rate = 100, weight = 7, size = 4.5, color = Color3.fromRGB(140, 225, 95) },
	{ key = "kopi", name = "Kopi Tubruk Raksasa", rarity = "Legendary", price = 10000, rate = 180, weight = 5, size = 5.0, color = Color3.fromRGB(185, 130, 85) },
	{ key = "gerobak", name = "Gerobak Bakso Terbang", rarity = "Legendary", price = 20000, rate = 300, weight = 3, size = 5.6, color = Color3.fromRGB(215, 110, 85) },
	{ key = "padang", name = "Nasi Padang Sejagat", rarity = "Mythic", price = 50000, rate = 500, weight = 2, size = 5.9, color = Color3.fromRGB(255, 240, 200) },
}

-- Conveyor: brainrots walk from startX to endX along z, on top of the belt.
-- The belt is a RAISED structure (3 studs tall, top at y=3): a flat 1-stud
-- belt read as ground from eye level. beltTopY must match the Belt part's
-- top in WorldBuilder; the spawner reads it for every placement.
Config.CONVEYOR = {
	startX = -72,
	endX = 72,
	z = 0,
	beltTopY = 3,
	speed = 3.5,
}
Config.SPAWN_INTERVAL = 5
Config.MAX_ON_CONVEYOR = 8

-- Six lapak (bases) in two rows of three, north and south of the conveyor.
Config.BASES = {
	{ x = -55, z = -28, color = Color3.fromRGB(255, 183, 3) },
	{ x = 0, z = -28, color = Color3.fromRGB(76, 201, 240) },
	{ x = 55, z = -28, color = Color3.fromRGB(255, 77, 109) },
	{ x = -55, z = 28, color = Color3.fromRGB(120, 220, 110) },
	{ x = 0, z = 28, color = Color3.fromRGB(255, 140, 40) },
	{ x = 55, z = 28, color = Color3.fromRGB(157, 78, 221) },
}
Config.BASE_SIZE = { x = 26, z = 20 }
Config.PEDESTALS_PER_BASE = 6
Config.PEDESTAL_OFFSETS = {
	{ x = -7, z = -3.5 },
	{ x = 0, z = -3.5 },
	{ x = 7, z = -3.5 },
	{ x = -7, z = 3.5 },
	{ x = 0, z = 3.5 },
	{ x = 7, z = 3.5 },
}

-- Gerobak Tsunami: a wave of carts sweeps the market on a timer.
Config.WAVE_INTERVAL = 90
Config.FIRST_WAVE_AT = 75
Config.WAVE_WARNING = 10
Config.WAVE_DURATION = 12

-- Kunci Lapak: lock your own base against stealing.
Config.LOCK_DURATION = 30
Config.LOCK_COOLDOWN = 90

-- Rebirths: reset cash for a permanent income multiplier and a title.
-- totalEarned is the lifetime earnings needed for that rebirth.
Config.REBIRTHS = {
	{ totalEarned = 25000, title = "Pedagang Keliling" },
	{ totalEarned = 150000, title = "Juragan Pasar" },
	{ totalEarned = 750000, title = "Sultan Brainrot" },
	{ totalEarned = 3000000, title = "Legenda Pasar Malam" },
}
Config.REBIRTH_BONUS_PER_LEVEL = 0.25

-- Upgrades. costs[i] buys level i; speed also lists the WalkSpeed per level.
Config.UPGRADES = {
	speed = { name = "Sepatu Kilat", desc = "Lari lebih cepat", costs = { 500, 2000, 6000 }, speeds = { 20, 24, 28 } },
	carry = { name = "Tangan Kedua", desc = "Bawa 2 brainrot sekaligus", costs = { 2500 } },
	income = { name = "Timbangan Emas", desc = "+25% $/detik per level", costs = { 1000, 4000, 12000 } },
}
Config.INCOME_BONUS_PER_LEVEL = 0.25

return Config
