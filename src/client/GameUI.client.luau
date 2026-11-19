-- GameUI.client.luau
-- The HUD for Pasar Brainrot. Money top-centre (never top-left, where
-- Roblox's own menu buttons sit), five action buttons down the right side,
-- a hint bar along the bottom, toasts bottom-right, and upgrade / index
-- panels that open over the middle. On touch devices without a keyboard the
-- right-side stack collapses into one small MENU pill, because the full
-- stack would cover the jump button and the camera area.
--
-- The client keeps its own copy of the character, rebirth and upgrade data:
-- Config lives on the server, where the client cannot require it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local LockBaseRemote = Remotes:WaitForChild("LockBase")
local RebirthRemote = Remotes:WaitForChild("RequestRebirth")
local UpgradeRemote = Remotes:WaitForChild("BuyUpgrade")
local Notify = Remotes:WaitForChild("Notify")
local WaveTimer = Remotes:WaitForChild("WaveTimer")

-- Palette and fonts. Display text is LuckiestGuy; labels are GothamBold /
-- GothamBlack. Never Bungee: it is not a Roblox font and breaks scripts.
local DARK = Color3.fromRGB(18, 10, 32)
local GOLD = Color3.fromRGB(255, 183, 3)
local PURPLE = Color3.fromRGB(157, 78, 221)
local CYAN = Color3.fromRGB(76, 201, 240)
local PINK = Color3.fromRGB(255, 77, 109)
local GREEN = Color3.fromRGB(120, 255, 140)
local WHITE = Color3.fromRGB(245, 240, 255)
local RED = Color3.fromRGB(255, 90, 90)

local DISPLAY_FONT = Enum.Font.LuckiestGuy
local LABEL_FONT = Enum.Font.GothamBold
local HEAVY_FONT = Enum.Font.GothamBlack

-- The cast, for the index panel. Prices and rates match the server's Config.
local CHARACTERS = {
	{ Name = "Bakso Berlari", Rarity = "Common", Price = 50, Rate = 5 },
	{ Name = "Es Teh Manis Terbang", Rarity = "Common", Price = 100, Rate = 8 },
	{ Name = "Gorengan Galak", Rarity = "Rare", Price = 400, Rate = 20 },
	{ Name = "Kucing Oren Ngamuk", Rarity = "Rare", Price = 800, Rate = 35 },
	{ Name = "Ayam Geprek Terbang", Rarity = "Epic", Price = 2000, Rate = 60 },
	{ Name = "Durian Meledak", Rarity = "Epic", Price = 4000, Rate = 100 },
	{ Name = "Kopi Tubruk Raksasa", Rarity = "Legendary", Price = 10000, Rate = 180 },
	{ Name = "Gerobak Bakso Terbang", Rarity = "Legendary", Price = 20000, Rate = 300 },
	{ Name = "Nasi Padang Sejagat", Rarity = "Mythic", Price = 50000, Rate = 500 },
}
local RARITY_COLORS = {
	Common = Color3.fromRGB(158, 227, 125),
	Rare = Color3.fromRGB(76, 201, 240),
	Epic = Color3.fromRGB(157, 78, 221),
	Legendary = Color3.fromRGB(255, 183, 3),
	Mythic = Color3.fromRGB(255, 77, 109),
}
local REBIRTH_NEEDS = { 25000, 150000, 750000, 3000000 }
local UPGRADES = {
	speed = { Name = "Sepatu Kilat", Desc = "Lari lebih cepat", Costs = { 500, 2000, 6000 } },
	carry = { Name = "Tangan Kedua", Desc = "Bawa 2 brainrot sekaligus", Costs = { 2500 } },
	income = { Name = "Timbangan Emas", Desc = "+25% $/detik per level", Costs = { 1000, 4000, 12000 } },
}
local UPGRADE_ORDER = { "speed", "carry", "income" }

-- 25000 -> "25.0K", 456 -> "456".
local function compact(n)
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	else
		return tostring(n)
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "PasarBrainrotHUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")

local function rounded(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function outlined(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function makeButton(parent, text, bgColor, size, position)
	local button = Instance.new("TextButton")
	button.Text = text
	button.Font = DISPLAY_FONT
	button.TextSize = 18
	button.TextColor3 = WHITE
	button.BackgroundColor3 = bgColor
	button.Size = size
	button.Position = position
	button.Parent = parent
	rounded(button, 10)
	outlined(button, Color3.fromRGB(255, 255, 255), 1, 0.75)
	return button
end

-- Money panel, top-centre, with a gold border.
local moneyPanel = Instance.new("Frame")
moneyPanel.Name = "MoneyPanel"
moneyPanel.AnchorPoint = Vector2.new(0.5, 0)
moneyPanel.Position = UDim2.new(0.5, 0, 0, 12)
moneyPanel.Size = UDim2.new(0, 360, 0, 84)
moneyPanel.BackgroundColor3 = DARK
moneyPanel.BackgroundTransparency = 0.15
moneyPanel.Parent = gui
rounded(moneyPanel, 12)
outlined(moneyPanel, GOLD, 2, 0)

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "Cash"
cashLabel.Text = "$250"
cashLabel.Font = DISPLAY_FONT
cashLabel.TextSize = 34
cashLabel.TextColor3 = GOLD
cashLabel.BackgroundTransparency = 1
cashLabel.Size = UDim2.new(1, 0, 0, 44)
cashLabel.Position = UDim2.new(0, 0, 0, 6)
cashLabel.Parent = moneyPanel
local cashScale = Instance.new("UIScale")
cashScale.Parent = cashLabel

local subLabel = Instance.new("TextLabel")
subLabel.Name = "Sub"
subLabel.Text = "$0/detik  •  x1.00  •  REBIRTH 0  •  Pemula Pasar"
subLabel.Font = LABEL_FONT
subLabel.TextSize = 15
subLabel.TextColor3 = WHITE
subLabel.BackgroundTransparency = 1
subLabel.Size = UDim2.new(1, 0, 0, 24)
subLabel.Position = UDim2.new(0, 0, 0, 52)
subLabel.Parent = moneyPanel

-- Wave countdown under the money panel. Pink, turning red under 15 seconds.
local waveLabel = Instance.new("TextLabel")
waveLabel.Name = "Wave"
waveLabel.Text = "GEROBAK TSUNAMI 1:15"
waveLabel.Font = HEAVY_FONT
waveLabel.TextSize = 16
waveLabel.TextColor3 = PINK
waveLabel.BackgroundTransparency = 1
waveLabel.AnchorPoint = Vector2.new(0.5, 0)
waveLabel.Position = UDim2.new(0.5, 0, 0, 104)
waveLabel.Size = UDim2.new(0, 360, 0, 26)
waveLabel.Parent = gui

-- Hint bar along the bottom.
local hintBar = Instance.new("Frame")
hintBar.Name = "HintBar"
hintBar.AnchorPoint = Vector2.new(0.5, 1)
hintBar.Position = UDim2.new(0.5, 0, 1, -16)
hintBar.Size = UDim2.new(0, 560, 0, 40)
hintBar.BackgroundColor3 = DARK
hintBar.BackgroundTransparency = 0.15
hintBar.Parent = gui
rounded(hintBar, 10)
outlined(hintBar, PURPLE, 1, 0.3)
local hintLabel = Instance.new("TextLabel")
hintLabel.Text = "Dekati brainrot di konveyor lalu tekan E untuk membeli"
hintLabel.Font = LABEL_FONT
hintLabel.TextSize = 15
hintLabel.TextColor3 = WHITE
hintLabel.BackgroundTransparency = 1
hintLabel.Size = UDim2.new(1, -16, 1, 0)
hintLabel.Position = UDim2.new(0, 8, 0, 0)
hintLabel.Parent = hintBar

-- The four action buttons. On PC they stack down the right side; on touch
-- devices they live inside the compact menu panel instead.
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local menuPanel = Instance.new("Frame")
menuPanel.Name = "MenuPanel"
menuPanel.AnchorPoint = Vector2.new(1, 0)
menuPanel.Position = UDim2.new(1, -16, 0, 174)
menuPanel.Size = UDim2.new(0, 204, 0, 216)
menuPanel.BackgroundColor3 = DARK
menuPanel.BackgroundTransparency = 0.15
menuPanel.Visible = false
menuPanel.Parent = gui
rounded(menuPanel, 12)
outlined(menuPanel, PURPLE, 1, 0.3)

local menuButton = Instance.new("TextButton")
menuButton.Name = "MenuButton"
menuButton.Text = "MENU"
menuButton.Font = DISPLAY_FONT
menuButton.TextSize = 16
menuButton.TextColor3 = WHITE
menuButton.BackgroundColor3 = Color3.fromRGB(50, 55, 80)
menuButton.AnchorPoint = Vector2.new(1, 0)
menuButton.Position = UDim2.new(1, -16, 0, 130)
menuButton.Size = UDim2.new(0, 90, 0, 36)
menuButton.Visible = isTouch
menuButton.Parent = gui
rounded(menuButton, 18)
outlined(menuButton, Color3.fromRGB(255, 255, 255), 1, 0.75)

local lockButton = makeButton(gui, "KUNCI LAPAK", Color3.fromRGB(20, 90, 100), UDim2.new(0, 188, 0, 48), UDim2.new(1, -16, 0, 130))
lockButton.AnchorPoint = Vector2.new(1, 0)
local rebirthButton = makeButton(gui, "REBIRTH 0/25.0K", Color3.fromRGB(140, 100, 10), UDim2.new(0, 188, 0, 48), UDim2.new(1, -16, 0, 186))
rebirthButton.AnchorPoint = Vector2.new(1, 0)
local upgradeButton = makeButton(gui, "UPGRADE", Color3.fromRGB(90, 40, 140), UDim2.new(0, 188, 0, 48), UDim2.new(1, -16, 0, 242))
upgradeButton.AnchorPoint = Vector2.new(1, 0)
local indexButton = makeButton(gui, "INDEX (9)", Color3.fromRGB(50, 55, 80), UDim2.new(0, 188, 0, 48), UDim2.new(1, -16, 0, 298))
indexButton.AnchorPoint = Vector2.new(1, 0)
local musicButton = makeButton(gui, "MUSIK: ON", CYAN, UDim2.new(0, 188, 0, 48), UDim2.new(1, -16, 0, 354))
musicButton.AnchorPoint = Vector2.new(1, 0)

if isTouch then
	-- The same five buttons, compacted into the menu panel.
	local compact = { lockButton, rebirthButton, upgradeButton, indexButton, musicButton }
	for i, button in ipairs(compact) do
		button.Parent = menuPanel
		button.AnchorPoint = Vector2.new(0, 0)
		button.Size = UDim2.new(0, 188, 0, 36)
		button.Position = UDim2.new(0, 8, 0, 8 + (i - 1) * 40)
	end
end

local function closeMenu()
	menuPanel.Visible = false
end

menuButton.MouseButton1Click:Connect(function()
	menuPanel.Visible = not menuPanel.Visible
end)

-- Toasts, bottom-right, stacked newest at the bottom.
local toasts = {}
local TOAST_COLORS = { good = GREEN, buy = GREEN, bad = RED, place = GOLD, rebirth = GOLD, steal = PINK, info = WHITE }

local function layoutToasts()
	for i, toast in ipairs(toasts) do
		toast.Position = UDim2.new(1, -356, 1, -16 - (i - 1) * 52 - 44)
	end
end

local function showToast(text, kind)
	local toast = Instance.new("Frame")
	toast.BackgroundColor3 = DARK
	toast.BackgroundTransparency = 0.1
	toast.Size = UDim2.new(0, 340, 0, 44)
	toast.Parent = gui
	rounded(toast, 10)
	outlined(toast, TOAST_COLORS[kind] or WHITE, 2, 0)
	local label = Instance.new("TextLabel")
	label.Text = text
	label.Font = LABEL_FONT
	label.TextSize = 14
	label.TextColor3 = WHITE
	label.BackgroundTransparency = 1
	label.TextWrapped = true
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.Parent = toast
	table.insert(toasts, 1, toast)
	layoutToasts()
	toast.BackgroundTransparency = 1
	label.TextTransparency = 1
	TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 0.1 }):Play()
	TweenService:Create(label, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	task.delay(3.5, function()
		local fade = TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		fade:Play()
		fade.Completed:Connect(function()
			for i, other in ipairs(toasts) do
				if other == toast then
					table.remove(toasts, i)
					break
				end
			end
			toast:Destroy()
			layoutToasts()
		end)
	end)
end

Notify.OnClientEvent:Connect(function(text, kind)
	showToast(text, kind or "info")
end)

-- Upgrade panel, centred, hidden until opened.
local upgradePanel = Instance.new("Frame")
upgradePanel.Name = "UpgradePanel"
upgradePanel.AnchorPoint = Vector2.new(0.5, 0.5)
upgradePanel.Position = UDim2.new(0.5, 0, 0.5, 0)
upgradePanel.Size = UDim2.new(0, 460, 0, 330)
upgradePanel.BackgroundColor3 = DARK
upgradePanel.BackgroundTransparency = 0.05
upgradePanel.Visible = false
upgradePanel.Parent = gui
rounded(upgradePanel, 14)
outlined(upgradePanel, GOLD, 2, 0)

local upgradeTitle = Instance.new("TextLabel")
upgradeTitle.Text = "UPGRADE"
upgradeTitle.Font = DISPLAY_FONT
upgradeTitle.TextSize = 26
upgradeTitle.TextColor3 = GOLD
upgradeTitle.BackgroundTransparency = 1
upgradeTitle.Size = UDim2.new(1, 0, 0, 44)
upgradeTitle.Position = UDim2.new(0, 0, 0, 8)
upgradeTitle.Parent = upgradePanel

local upgradeClose = makeButton(upgradePanel, "X", Color3.fromRGB(120, 30, 30), UDim2.new(0, 36, 0, 36), UDim2.new(1, -44, 0, 8))
upgradeClose.TextSize = 20

local upgradeRows = {}
for i, id in ipairs(UPGRADE_ORDER) do
	local def = UPGRADES[id]
	local row = Instance.new("Frame")
	row.BackgroundColor3 = Color3.fromRGB(35, 22, 55)
	row.Size = UDim2.new(0, 420, 0, 64)
	row.Position = UDim2.new(0, 20, 0, 60 + (i - 1) * 76)
	row.Parent = upgradePanel
	rounded(row, 10)
	local name = Instance.new("TextLabel")
	name.Text = def.Name
	name.Font = DISPLAY_FONT
	name.TextSize = 18
	name.TextColor3 = WHITE
	name.BackgroundTransparency = 1
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Size = UDim2.new(0, 220, 0, 26)
	name.Position = UDim2.new(0, 12, 0, 6)
	name.Parent = row
	local desc = Instance.new("TextLabel")
	desc.Text = def.Desc
	desc.Font = LABEL_FONT
	desc.TextSize = 13
	desc.TextColor3 = Color3.fromRGB(200, 190, 220)
	desc.BackgroundTransparency = 1
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Size = UDim2.new(0, 220, 0, 22)
	desc.Position = UDim2.new(0, 12, 0, 32)
	desc.Parent = row
	local level = Instance.new("TextLabel")
	level.Text = "Lv 0/3"
	level.Font = HEAVY_FONT
	level.TextSize = 14
	level.TextColor3 = CYAN
	level.BackgroundTransparency = 1
	level.Size = UDim2.new(0, 70, 0, 24)
	level.Position = UDim2.new(0, 240, 0, 20)
	level.Parent = row
	local buy = makeButton(row, "$500", Color3.fromRGB(30, 120, 50), UDim2.new(0, 90, 0, 36), UDim2.new(0, 318, 0, 14))
	buy.TextSize = 16
	buy.MouseButton1Click:Connect(function()
		UpgradeRemote:FireServer(id)
	end)
	upgradeRows[id] = { Level = level, Buy = buy }
end

local function upgradeLevel(id)
	if id == "speed" then
		return player:GetAttribute("SpeedLevel") or 0
	elseif id == "income" then
		return player:GetAttribute("IncomeLevel") or 0
	elseif id == "carry" then
		return (player:GetAttribute("CarryCapacity") or 1) - 1
	end
	return 0
end

local function refreshUpgradePanel()
	for id, row in pairs(upgradeRows) do
		local def = UPGRADES[id]
		local level = upgradeLevel(id)
		row.Level.Text = "Lv " .. level .. "/" .. #def.Costs
		local nextCost = def.Costs[level + 1]
		if nextCost then
			row.Buy.Text = "$" .. nextCost
			row.Buy.BackgroundColor3 = Color3.fromRGB(30, 120, 50)
		else
			row.Buy.Text = "MAX"
			row.Buy.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		end
	end
end

-- Index panel, centred, hidden until opened: a 3x3 grid of character cards.
local indexPanel = Instance.new("Frame")
indexPanel.Name = "IndexPanel"
indexPanel.AnchorPoint = Vector2.new(0.5, 0.5)
indexPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
indexPanel.Size = UDim2.new(0, 560, 0, 380)
indexPanel.BackgroundColor3 = DARK
indexPanel.BackgroundTransparency = 0.05
indexPanel.Visible = false
indexPanel.Parent = gui
rounded(indexPanel, 14)
outlined(indexPanel, CYAN, 2, 0)

local indexTitle = Instance.new("TextLabel")
indexTitle.Text = "INDEX BRAINROT"
indexTitle.Font = DISPLAY_FONT
indexTitle.TextSize = 26
indexTitle.TextColor3 = CYAN
indexTitle.BackgroundTransparency = 1
indexTitle.Size = UDim2.new(1, 0, 0, 44)
indexTitle.Position = UDim2.new(0, 0, 0, 8)
indexTitle.Parent = indexPanel

local indexClose = makeButton(indexPanel, "X", Color3.fromRGB(120, 30, 30), UDim2.new(0, 36, 0, 36), UDim2.new(1, -44, 0, 8))
indexClose.TextSize = 20

local grid = Instance.new("Frame")
grid.BackgroundTransparency = 1
grid.Size = UDim2.new(0, 520, 0, 310)
grid.Position = UDim2.new(0, 20, 0, 58)
grid.Parent = indexPanel
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 168, 0, 96)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
gridLayout.Parent = grid

for _, character in ipairs(CHARACTERS) do
	local card = Instance.new("Frame")
	card.BackgroundColor3 = Color3.fromRGB(35, 22, 55)
	card.Parent = grid
	rounded(card, 10)
	local name = Instance.new("TextLabel")
	name.Text = character.Name
	name.Font = DISPLAY_FONT
	name.TextSize = 14
	name.TextColor3 = RARITY_COLORS[character.Rarity] or WHITE
	name.BackgroundTransparency = 1
	name.TextWrapped = true
	name.Size = UDim2.new(1, -12, 0, 40)
	name.Position = UDim2.new(0, 6, 0, 6)
	name.Parent = card
	local info = Instance.new("TextLabel")
	info.Text = string.upper(character.Rarity) .. "  •  $" .. character.Rate .. "/detik"
	info.Font = LABEL_FONT
	info.TextSize = 12
	info.TextColor3 = WHITE
	info.BackgroundTransparency = 1
	info.Size = UDim2.new(1, -12, 0, 20)
	info.Position = UDim2.new(0, 6, 0, 48)
	info.Parent = card
	local price = Instance.new("TextLabel")
	price.Text = "$" .. character.Price
	price.Font = HEAVY_FONT
	price.TextSize = 15
	price.TextColor3 = GREEN
	price.BackgroundTransparency = 1
	price.Size = UDim2.new(1, -12, 0, 22)
	price.Position = UDim2.new(0, 6, 0, 68)
	price.Parent = card
end

-- The panels toggle each other: opening one closes the other.
local function openUpgrade()
	upgradePanel.Visible = true
	indexPanel.Visible = false
	refreshUpgradePanel()
end

local function openIndex()
	indexPanel.Visible = true
	upgradePanel.Visible = false
end

upgradeButton.MouseButton1Click:Connect(function()
	if upgradePanel.Visible then
		upgradePanel.Visible = false
	else
		openUpgrade()
	end
	closeMenu()
end)
indexButton.MouseButton1Click:Connect(function()
	if indexPanel.Visible then
		indexPanel.Visible = false
	else
		openIndex()
	end
	closeMenu()
end)
upgradeClose.MouseButton1Click:Connect(function()
	upgradePanel.Visible = false
end)
indexClose.MouseButton1Click:Connect(function()
	indexPanel.Visible = false
end)
lockButton.MouseButton1Click:Connect(function()
	LockBaseRemote:FireServer()
	closeMenu()
end)
rebirthButton.MouseButton1Click:Connect(function()
	RebirthRemote:FireServer()
	closeMenu()
end)
local musicOn = true
musicButton.MouseButton1Click:Connect(function()
	-- Fire the toggle the Music script listens on; create it if that script
	-- has not run yet. Then flip this button's own label to match.
	local toggle = ReplicatedStorage:FindFirstChild("MusicToggle")
	if not toggle then
		toggle = Instance.new("BindableEvent")
		toggle.Name = "MusicToggle"
		toggle.Parent = ReplicatedStorage
	end
	toggle:Fire()
	musicOn = not musicOn
	if musicOn then
		musicButton.Text = "MUSIK: ON"
	else
		musicButton.Text = "MUSIK: OFF"
	end
	closeMenu()
end)

-- Live updates from leaderstats, attributes and the wave timer.
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")
local incomeValue = leaderstats:WaitForChild("Income")
local rebirthValue = leaderstats:WaitForChild("Rebirths")
local lastCash = cashValue.Value

local function refreshMoney()
	local cash = cashValue.Value
	cashLabel.Text = "$" .. cash
	local multiplier = player:GetAttribute("Multiplier") or 1
	local title = player:GetAttribute("RebirthTitle") or "Pemula Pasar"
	subLabel.Text = "$" .. incomeValue.Value .. "/detik  •  x" .. string.format("%.2f", multiplier) .. "  •  REBIRTH " .. rebirthValue.Value .. "  •  " .. title
	-- A quick scale pop on every income tick.
	if cash > lastCash then
		TweenService:Create(cashScale, TweenInfo.new(0.12), { Scale = 1.15 }):Play()
		task.delay(0.12, function()
			TweenService:Create(cashScale, TweenInfo.new(0.12), { Scale = 1 }):Play()
		end)
	end
	lastCash = cash
end

local function refreshRebirthButton()
	local earned = player:GetAttribute("TotalEarned") or 0
	local nextNeed = REBIRTH_NEEDS[rebirthValue.Value + 1]
	if nextNeed then
		rebirthButton.Text = "REBIRTH " .. compact(earned) .. "/" .. compact(nextNeed)
	else
		rebirthButton.Text = "REBIRTH MAX"
	end
end

local function refreshHint()
	local names = player:GetAttribute("CarriedNames") or ""
	if names == "" then
		hintLabel.Text = "Dekati brainrot di konveyor lalu tekan E untuk membeli"
		hintLabel.TextColor3 = WHITE
	else
		hintLabel.Text = "MEMBAWA: " .. names .. " — bawa ke lapakmu untuk menaruh!"
		hintLabel.TextColor3 = GOLD
	end
end

local function refreshWave()
	local secs = WaveTimer.Value
	local mins = math.floor(secs / 60)
	local rest = secs % 60
	waveLabel.Text = "GEROBAK TSUNAMI " .. mins .. ":" .. string.format("%02d", rest)
	if secs < 15 then
		waveLabel.TextColor3 = RED
	else
		waveLabel.TextColor3 = PINK
	end
end

cashValue.Changed:Connect(refreshMoney)
incomeValue.Changed:Connect(refreshMoney)
rebirthValue.Changed:Connect(function()
	refreshMoney()
	refreshRebirthButton()
end)
player:GetAttributeChangedSignal("TotalEarned"):Connect(function()
	refreshMoney()
	refreshRebirthButton()
end)
player:GetAttributeChangedSignal("Multiplier"):Connect(refreshMoney)
player:GetAttributeChangedSignal("RebirthTitle"):Connect(refreshMoney)
player:GetAttributeChangedSignal("CarriedNames"):Connect(refreshHint)
player:GetAttributeChangedSignal("SpeedLevel"):Connect(refreshUpgradePanel)
player:GetAttributeChangedSignal("IncomeLevel"):Connect(refreshUpgradePanel)
player:GetAttributeChangedSignal("CarryCapacity"):Connect(refreshUpgradePanel)
WaveTimer:GetPropertyChangedSignal("Value"):Connect(refreshWave)

-- The lock button counts down while the lapak is locked.
task.spawn(function()
	while true do
		task.wait(0.5)
		local lockedUntil = player:GetAttribute("BaseLockedUntil") or 0
		local left = lockedUntil - os.time()
		if left > 0 then
			lockButton.Text = "TERKUNCI " .. left .. " dtk"
		else
			lockButton.Text = "KUNCI LAPAK"
		end
	end
end)

refreshMoney()
refreshRebirthButton()
refreshHint()
refreshWave()

-- Title overlay: full-screen, fades out on click or on its own after 8 seconds.
local overlay = Instance.new("Frame")
overlay.Name = "TitleOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(12, 6, 24)
overlay.BackgroundTransparency = 0.1
overlay.ZIndex = 10
overlay.Parent = gui

local overlayClick = Instance.new("TextButton")
overlayClick.Text = ""
overlayClick.BackgroundTransparency = 1
overlayClick.Size = UDim2.new(1, 0, 1, 0)
overlayClick.ZIndex = 11
overlayClick.Parent = overlay

local overlayTitle = Instance.new("TextLabel")
overlayTitle.Text = "PASAR BRAINROT"
overlayTitle.Font = DISPLAY_FONT
overlayTitle.TextSize = 64
overlayTitle.TextColor3 = GOLD
overlayTitle.BackgroundTransparency = 1
overlayTitle.Size = UDim2.new(1, 0, 0, 80)
overlayTitle.Position = UDim2.new(0, 0, 0.28, 0)
overlayTitle.ZIndex = 12
overlayTitle.Parent = overlay

local overlaySub = Instance.new("TextLabel")
overlaySub.Text = "Beli brainrot  •  Bawa pulang  •  Jadi kaya!"
overlaySub.Font = LABEL_FONT
overlaySub.TextSize = 20
overlaySub.TextColor3 = WHITE
overlaySub.BackgroundTransparency = 1
overlaySub.Size = UDim2.new(1, 0, 0, 30)
overlaySub.Position = UDim2.new(0, 0, 0.28, 84)
overlaySub.ZIndex = 12
overlaySub.Parent = overlay

local overlayControls = Instance.new("TextLabel")
overlayControls.Text = "WASD jalan  •  E beli / ambil  •  Tombol di kanan: kunci, rebirth, upgrade, index"
overlayControls.Font = LABEL_FONT
overlayControls.TextSize = 16
overlayControls.TextColor3 = Color3.fromRGB(200, 190, 220)
overlayControls.BackgroundTransparency = 1
overlayControls.Size = UDim2.new(1, 0, 0, 26)
overlayControls.Position = UDim2.new(0, 0, 0.28, 120)
overlayControls.ZIndex = 12
overlayControls.Parent = overlay

local startButton = makeButton(overlay, "MULAI MAIN", GOLD, UDim2.new(0, 220, 0, 56), UDim2.new(0.5, -110, 0.28, 170))
startButton.TextSize = 24
startButton.TextColor3 = Color3.fromRGB(30, 18, 0)
startButton.ZIndex = 12

local overlayGone = false
local function hideOverlay()
	if overlayGone then
		return
	end
	overlayGone = true
	TweenService:Create(overlay, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	for _, child in ipairs({ overlayTitle, overlaySub, overlayControls }) do
		TweenService:Create(child, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
	end
	TweenService:Create(startButton, TweenInfo.new(0.6), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
	task.delay(0.65, function()
		overlay:Destroy()
	end)
end

overlayClick.MouseButton1Click:Connect(hideOverlay)
startButton.MouseButton1Click:Connect(hideOverlay)
task.delay(8, hideOverlay)
