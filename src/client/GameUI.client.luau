-- Pasar Brainrot HUD: money big at top-CENTRE (never top-left, where Roblox
-- menu buttons cover it), action buttons down the right side, upgrade and
-- index panels, toasts and the title overlay. Prices and names below are a
-- display-only copy; the server stays authoritative on every purchase.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local playerGui = player:WaitForChild("PlayerGui")

-- Palette: dark night market, warm gold, neon accents.
local GOLD = Color3.fromRGB(255, 183, 3)
local DARK = Color3.fromRGB(18, 10, 32)
local DARK2 = Color3.fromRGB(30, 20, 55)
local PURPLE = Color3.fromRGB(157, 78, 221)
local CYAN = Color3.fromRGB(76, 201, 240)
local PINK = Color3.fromRGB(255, 77, 109)
local GREEN = Color3.fromRGB(120, 255, 140)
local WHITE = Color3.fromRGB(245, 240, 255)
local RED = Color3.fromRGB(255, 90, 90)

-- Display-only copies of the server tuning (see src/server/Config.luau).
local UPGRADE_DISPLAY = {
	{ id = "speed", name = "Sepatu Kilat", desc = "Lari lebih cepat", costs = { 500, 2000, 6000 } },
	{ id = "carry", name = "Tangan Kedua", desc = "Bawa 2 brainrot sekaligus", costs = { 2500 } },
	{ id = "income", name = "Timbangan Emas", desc = "+25% $/detik per level", costs = { 1000, 4000, 12000 } },
}
local CHARACTER_DISPLAY = {
	{ name = "Bakso Berlari", rarity = "Common", rate = 5, price = 50, color = Color3.fromRGB(158, 227, 125) },
	{ name = "Es Teh Manis Terbang", rarity = "Common", rate = 8, price = 100, color = Color3.fromRGB(158, 227, 125) },
	{ name = "Gorengan Galak", rarity = "Rare", rate = 20, price = 400, color = Color3.fromRGB(76, 201, 240) },
	{ name = "Kucing Oren Ngamuk", rarity = "Rare", rate = 35, price = 800, color = Color3.fromRGB(76, 201, 240) },
	{ name = "Ayam Geprek Terbang", rarity = "Epic", rate = 60, price = 2000, color = Color3.fromRGB(157, 78, 221) },
	{ name = "Durian Meledak", rarity = "Epic", rate = 100, price = 4000, color = Color3.fromRGB(157, 78, 221) },
	{ name = "Kopi Tubruk Raksasa", rarity = "Legendary", rate = 180, price = 10000, color = Color3.fromRGB(255, 183, 3) },
	{ name = "Gerobak Bakso Terbang", rarity = "Legendary", rate = 300, price = 20000, color = Color3.fromRGB(255, 183, 3) },
	{ name = "Nasi Padang Sejagat", rarity = "Mythic", rate = 500, price = 50000, color = Color3.fromRGB(255, 77, 109) },
}
local REBIRTH_THRESHOLDS = { 25000, 150000, 750000, 3000000 }

local function formatMoney(n)
	local s = tostring(math.floor(n))
	local out = ""
	while #s > 3 do
		out = "," .. string.sub(s, -3) .. out
		s = string.sub(s, 1, -4)
	end
	return "$" .. s .. out
end

local function formatCompact(n)
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fk", n / 1000)
	end
	return tostring(math.floor(n))
end

local function addCorner(gui, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = gui
	return corner
end

local function addStroke(gui, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 2
	stroke.Parent = gui
	return stroke
end

local function makeLabel(parent, name, text, size, font, color, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = textSize
	label.Font = font
	label.TextStrokeTransparency = 0.3
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, position, bg, font, textSize)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = bg
	button.Text = text
	button.TextColor3 = WHITE
	button.TextSize = textSize
	button.Font = font
	button.TextStrokeTransparency = 0.3
	button.AutoButtonColor = true
	button.Parent = parent
	addCorner(button, 10)
	return button
end

-- Root HUD.
local gui = Instance.new("ScreenGui")
gui.Name = "PasarBrainrotHUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = playerGui

-- Money panel, top-centre.
local cashPanel = Instance.new("Frame")
cashPanel.Name = "CashPanel"
cashPanel.AnchorPoint = Vector2.new(0.5, 0)
cashPanel.Position = UDim2.new(0.5, 0, 0, 12)
cashPanel.Size = UDim2.fromOffset(360, 84)
cashPanel.BackgroundColor3 = DARK
cashPanel.BackgroundTransparency = 0.25
cashPanel.Parent = gui
addCorner(cashPanel, 14)
addStroke(cashPanel, GOLD, 2)
local moneyLabel = makeLabel(cashPanel, "Money", "$250", UDim2.new(1, 0, 0, 44), Enum.Font.LuckiestGuy, GOLD, 34)
moneyLabel.Position = UDim2.new(0, 0, 0, 4)
local subLabel = makeLabel(cashPanel, "Sub", "$0/detik  •  x1.00  •  REBIRTH 0", UDim2.new(1, 0, 0, 26), Enum.Font.GothamBold, WHITE, 15)
subLabel.Position = UDim2.new(0, 0, 0, 50)
local waveLabel = makeLabel(gui, "WaveTimer", "GEROBAK TSUNAMI 1:15", UDim2.new(0, 360, 0, 24), Enum.Font.GothamBold, PINK, 14)
waveLabel.AnchorPoint = Vector2.new(0.5, 0)
waveLabel.Position = UDim2.new(0.5, 0, 0, 102)

-- Action buttons down the right side.
local buttonColumn = Instance.new("Frame")
buttonColumn.Name = "Buttons"
buttonColumn.AnchorPoint = Vector2.new(1, 0)
buttonColumn.Position = UDim2.new(1, -14, 0, 130)
buttonColumn.Size = UDim2.fromOffset(188, 224)
buttonColumn.BackgroundTransparency = 1
buttonColumn.Parent = gui
local lockButton = makeButton(buttonColumn, "Lock", "KUNCI LAPAK", UDim2.fromOffset(188, 48), UDim2.fromOffset(0, 0), Color3.fromRGB(20, 90, 120), Enum.Font.LuckiestGuy, 17)
local rebirthButton = makeButton(buttonColumn, "Rebirth", "REBIRTH", UDim2.fromOffset(188, 48), UDim2.fromOffset(0, 56), Color3.fromRGB(150, 100, 10), Enum.Font.LuckiestGuy, 17)
local upgradeButton = makeButton(buttonColumn, "Upgrade", "UPGRADE", UDim2.fromOffset(188, 48), UDim2.fromOffset(0, 112), Color3.fromRGB(80, 40, 130), Enum.Font.LuckiestGuy, 17)
local indexButton = makeButton(buttonColumn, "Index", "INDEX (9)", UDim2.fromOffset(188, 48), UDim2.fromOffset(0, 168), Color3.fromRGB(50, 45, 80), Enum.Font.LuckiestGuy, 17)

-- Carried / hint bar, bottom-centre.
local carriedBar = Instance.new("Frame")
carriedBar.Name = "CarriedBar"
carriedBar.AnchorPoint = Vector2.new(0.5, 1)
carriedBar.Position = UDim2.new(0.5, 0, 1, -14)
carriedBar.Size = UDim2.fromOffset(560, 40)
carriedBar.BackgroundColor3 = DARK
carriedBar.BackgroundTransparency = 0.3
carriedBar.Parent = gui
addCorner(carriedBar, 10)
addStroke(carriedBar, PURPLE, 2)
local carriedLabel = makeLabel(carriedBar, "Text", "Dekati brainrot di konveyor lalu tekan E untuk membeli", UDim2.new(1, -16, 1, 0), Enum.Font.GothamBold, WHITE, 16)
carriedLabel.Position = UDim2.new(0, 8, 0, 0)

-- Toasts, bottom-right.
local toastBox = Instance.new("Frame")
toastBox.Name = "Toasts"
toastBox.AnchorPoint = Vector2.new(1, 1)
toastBox.Position = UDim2.new(1, -14, 1, -66)
toastBox.Size = UDim2.fromOffset(340, 220)
toastBox.BackgroundTransparency = 1
toastBox.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.FillDirection = Enum.FillDirection.Vertical
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.Padding = UDim.new(0, 6)
toastLayout.Parent = toastBox

local TOAST_COLORS = { good = GREEN, bad = RED, info = WHITE, buy = GREEN, place = GOLD, steal = PINK, rebirth = GOLD }

local function showToast(text, kind)
	local toast = Instance.new("Frame")
	toast.Size = UDim2.fromOffset(340, 44)
	toast.BackgroundColor3 = DARK2
	toast.BackgroundTransparency = 0.15
	toast.Parent = toastBox
	addCorner(toast, 8)
	addStroke(toast, TOAST_COLORS[kind] or WHITE, 2)
	local label = makeLabel(toast, "Text", text, UDim2.new(1, -16, 1, 0), Enum.Font.GothamBold, WHITE, 15)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	toast.BackgroundTransparency = 1
	label.TextTransparency = 1
	TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(label, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	task.delay(3.5, function()
		if toast.Parent then
			TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			task.wait(0.45)
			toast:Destroy()
		end
	end)
end

-- Upgrade panel.
local upgradePanel = Instance.new("Frame")
upgradePanel.Name = "UpgradePanel"
upgradePanel.AnchorPoint = Vector2.new(0.5, 0.5)
upgradePanel.Position = UDim2.fromScale(0.5, 0.5)
upgradePanel.Size = UDim2.fromOffset(460, 330)
upgradePanel.BackgroundColor3 = DARK
upgradePanel.BackgroundTransparency = 0.08
upgradePanel.Visible = false
upgradePanel.Parent = gui
addCorner(upgradePanel, 14)
addStroke(upgradePanel, PURPLE, 2)
makeLabel(upgradePanel, "Title", "UPGRADE", UDim2.new(1, 0, 0, 44), Enum.Font.LuckiestGuy, GOLD, 26).Position = UDim2.new(0, 0, 0, 8)
local upgradeClose = makeButton(upgradePanel, "Close", "X", UDim2.fromOffset(36, 36), UDim2.new(1, -44, 0, 8), Color3.fromRGB(120, 30, 40), Enum.Font.GothamBlack, 18)
upgradeClose.MouseButton1Click:Connect(function()
	upgradePanel.Visible = false
end)
local upgradeRows = {}
for i, up in ipairs(UPGRADE_DISPLAY) do
	local row = Instance.new("Frame")
	row.Name = up.id
	row.Position = UDim2.new(0, 16, 0, 60 + (i - 1) * 84)
	row.Size = UDim2.new(1, -32, 0, 74)
	row.BackgroundColor3 = DARK2
	row.Parent = upgradePanel
	addCorner(row, 10)
	makeLabel(row, "Name", up.name, UDim2.new(0.6, 0, 0, 26), Enum.Font.LuckiestGuy, WHITE, 18).Position = UDim2.new(0, 12, 0, 6)
	makeLabel(row, "Desc", up.desc, UDim2.new(0.6, 0, 0, 22), Enum.Font.GothamBold, Color3.fromRGB(200, 190, 220), 13).Position = UDim2.new(0, 12, 0, 34)
	local levelLabel = makeLabel(row, "Level", "Lv 0/" .. #up.costs, UDim2.new(0, 60, 0, 26), Enum.Font.GothamBlack, CYAN, 15)
	levelLabel.Position = UDim2.new(0.55, 0, 0, 6)
	local buyButton = makeButton(row, "Buy", "$" .. up.costs[1], UDim2.fromOffset(110, 40), UDim2.new(1, -122, 0, 17), Color3.fromRGB(20, 120, 60), Enum.Font.LuckiestGuy, 16)
	buyButton.MouseButton1Click:Connect(function()
		remotes.BuyUpgrade:FireServer(up.id)
	end)
	upgradeRows[up.id] = { row = row, levelLabel = levelLabel, buyButton = buyButton }
end

local function refreshUpgradePanel()
	local speedLevel = player:GetAttribute("SpeedLevel") or 0
	local carryLevel = (player:GetAttribute("CarryCapacity") or 1) - 1
	local incomeLevel = player:GetAttribute("IncomeLevel") or 0
	local levels = { speed = speedLevel, carry = carryLevel, income = incomeLevel }
	for _, up in ipairs(UPGRADE_DISPLAY) do
		local row = upgradeRows[up.id]
		local level = levels[up.id]
		row.levelLabel.Text = "Lv " .. level .. "/" .. #up.costs
		if level >= #up.costs then
			row.buyButton.Text = "MAX"
			row.buyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		else
			row.buyButton.Text = formatMoney(up.costs[level + 1])
			row.buyButton.BackgroundColor3 = Color3.fromRGB(20, 120, 60)
		end
	end
end

-- Index panel: the full cast of nine.
local indexPanel = Instance.new("Frame")
indexPanel.Name = "IndexPanel"
indexPanel.AnchorPoint = Vector2.new(0.5, 0.5)
indexPanel.Position = UDim2.fromScale(0.5, 0.5)
indexPanel.Size = UDim2.fromOffset(560, 380)
indexPanel.BackgroundColor3 = DARK
indexPanel.BackgroundTransparency = 0.08
indexPanel.Visible = false
indexPanel.Parent = gui
addCorner(indexPanel, 14)
addStroke(indexPanel, GOLD, 2)
makeLabel(indexPanel, "Title", "INDEX BRAINROT", UDim2.new(1, 0, 0, 44), Enum.Font.LuckiestGuy, GOLD, 26).Position = UDim2.new(0, 0, 0, 8)
local indexClose = makeButton(indexPanel, "Close", "X", UDim2.fromOffset(36, 36), UDim2.new(1, -44, 0, 8), Color3.fromRGB(120, 30, 40), Enum.Font.GothamBlack, 18)
indexClose.MouseButton1Click:Connect(function()
	indexPanel.Visible = false
end)
for i, char in ipairs(CHARACTER_DISPLAY) do
	local col = (i - 1) % 3
	local rowIdx = math.floor((i - 1) / 3)
	local card = Instance.new("Frame")
	card.Name = char.name
	card.Position = UDim2.new(0, 16 + col * 178, 0, 60 + rowIdx * 100)
	card.Size = UDim2.fromOffset(168, 90)
	card.BackgroundColor3 = DARK2
	card.Parent = indexPanel
	addCorner(card, 10)
	addStroke(card, char.color, 2)
	local nameLabel = makeLabel(card, "Name", char.name, UDim2.new(1, -12, 0, 34), Enum.Font.LuckiestGuy, char.color, 14)
	nameLabel.Position = UDim2.new(0, 6, 0, 6)
	nameLabel.TextWrapped = true
	makeLabel(card, "Rate", char.rarity:upper() .. "  •  $" .. char.rate .. "/detik", UDim2.new(1, -12, 0, 22), Enum.Font.GothamBold, WHITE, 13).Position = UDim2.new(0, 6, 0, 42)
	makeLabel(card, "Price", formatMoney(char.price), UDim2.new(1, -12, 0, 22), Enum.Font.GothamBlack, GREEN, 14).Position = UDim2.new(0, 6, 0, 62)
end

-- Live displays.
local stats = player:WaitForChild("leaderstats", 10)
local cashValue = stats and stats:WaitForChild("Cash", 5)
local incomeValue = stats and stats:WaitForChild("Income", 5)
local rebirthValue = stats and stats:WaitForChild("Rebirths", 5)

local function updateCashDisplay()
	local cash = cashValue and cashValue.Value or 0
	local income = incomeValue and incomeValue.Value or 0
	local rebirths = rebirthValue and rebirthValue.Value or 0
	local mult = player:GetAttribute("Multiplier") or 1
	local title = player:GetAttribute("RebirthTitle") or ""
	moneyLabel.Text = formatMoney(cash)
	subLabel.Text = formatMoney(income) .. "/detik  •  x" .. string.format("%.2f", mult) .. "  •  REBIRTH " .. rebirths .. "  •  " .. title
	-- Cash pulse: a quick scale pop on every income tick.
	TweenService:Create(moneyLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextSize = 38 }):Play()
	task.delay(0.13, function()
		TweenService:Create(moneyLabel, TweenInfo.new(0.18), { TextSize = 34 }):Play()
	end)
end

local function updateRebirthButton()
	local totalEarned = player:GetAttribute("TotalEarned") or 0
	local rebirths = rebirthValue and rebirthValue.Value or 0
	local nextThreshold = REBIRTH_THRESHOLDS[rebirths + 1]
	if not nextThreshold then
		rebirthButton.Text = "REBIRTH MAX"
	else
		rebirthButton.Text = "REBIRTH " .. formatCompact(totalEarned) .. "/" .. formatCompact(nextThreshold)
	end
end

local function updateCarriedBar()
	local names = player:GetAttribute("CarriedNames") or ""
	if names ~= "" then
		carriedLabel.Text = "MEMBAWA: " .. names .. "  —  bawa ke lapakmu untuk menaruh!"
		carriedLabel.TextColor3 = GOLD
	else
		carriedLabel.Text = "Dekati brainrot di konveyor lalu tekan E untuk membeli"
		carriedLabel.TextColor3 = WHITE
	end
end

local function updateWaveLabel(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	waveLabel.Text = "GEROBAK TSUNAMI " .. m .. ":" .. string.format("%02d", s)
	if seconds <= 15 then
		waveLabel.TextColor3 = RED
	else
		waveLabel.TextColor3 = PINK
	end
end

if cashValue then
	cashValue:GetPropertyChangedSignal("Value"):Connect(updateCashDisplay)
end
if incomeValue then
	incomeValue:GetPropertyChangedSignal("Value"):Connect(updateCashDisplay)
end
if rebirthValue then
	rebirthValue:GetPropertyChangedSignal("Value"):Connect(function()
		updateCashDisplay()
		updateRebirthButton()
	end)
end
player:GetAttributeChangedSignal("Multiplier"):Connect(updateCashDisplay)
player:GetAttributeChangedSignal("TotalEarned"):Connect(updateRebirthButton)
player:GetAttributeChangedSignal("CarriedNames"):Connect(updateCarriedBar)
player:GetAttributeChangedSignal("RebirthTitle"):Connect(updateCashDisplay)

local waveTimerValue = remotes:WaitForChild("WaveTimer", 10)
if waveTimerValue then
	waveTimerValue:GetPropertyChangedSignal("Value"):Connect(function()
		updateWaveLabel(waveTimerValue.Value)
	end)
	updateWaveLabel(waveTimerValue.Value)
end

-- Lock button countdown, refreshed four times a second.
task.spawn(function()
	while true do
		task.wait(0.25)
		local lockedUntil = player:GetAttribute("BaseLockedUntil") or 0
		local left = lockedUntil - os.time()
		if left > 0 then
			lockButton.Text = "TERKUNCI " .. left .. " dtk"
			lockButton.BackgroundColor3 = Color3.fromRGB(20, 120, 120)
		else
			lockButton.Text = "KUNCI LAPAK"
			lockButton.BackgroundColor3 = Color3.fromRGB(20, 90, 120)
		end
	end
end)

-- Buttons.
lockButton.MouseButton1Click:Connect(function()
	remotes.LockBase:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	remotes.RequestRebirth:FireServer()
end)
upgradeButton.MouseButton1Click:Connect(function()
	refreshUpgradePanel()
	upgradePanel.Visible = not upgradePanel.Visible
	indexPanel.Visible = false
end)
indexButton.MouseButton1Click:Connect(function()
	indexPanel.Visible = not indexPanel.Visible
	upgradePanel.Visible = false
end)

remotes.Notify.OnClientEvent:Connect(function(text, kind)
	showToast(text, kind)
	if kind == "good" and upgradePanel.Visible then
		refreshUpgradePanel()
	end
end)

updateCashDisplay()
updateRebirthButton()
updateCarriedBar()

-- Title overlay: fades on click, or on its own after 8 seconds.
local titleOverlay = Instance.new("TextButton")
titleOverlay.Name = "TitleOverlay"
titleOverlay.Size = UDim2.fromScale(1, 1)
titleOverlay.BackgroundColor3 = Color3.fromRGB(10, 6, 20)
titleOverlay.BackgroundTransparency = 0.15
titleOverlay.Text = ""
titleOverlay.AutoButtonColor = false
titleOverlay.Parent = gui
local titleLabel = makeLabel(titleOverlay, "Title", "PASAR BRAINROT", UDim2.new(1, 0, 0, 80), Enum.Font.LuckiestGuy, GOLD, 56)
titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
titleLabel.Position = UDim2.new(0.5, 0, 0.38, 0)
makeLabel(titleOverlay, "Sub", "Pasar malam 3D  •  Beli brainrot  •  Bawa pulang  •  Jadi kaya", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBold, WHITE, 18).Position = UDim2.new(0, 0, 0.46, 0)
makeLabel(titleOverlay, "Controls", "WASD jalan  •  E beli / ambil  •  Tombol di kanan: kunci, rebirth, upgrade, index", UDim2.new(1, 0, 0, 26), Enum.Font.GothamBold, Color3.fromRGB(200, 190, 220), 15).Position = UDim2.new(0, 0, 0.52, 0)
local startButton = makeButton(titleOverlay, "Start", "MULAI MAIN", UDim2.fromOffset(260, 60), UDim2.new(0.5, -130, 0.6, 0), Color3.fromRGB(180, 120, 10), Enum.Font.LuckiestGuy, 24)
local dismissed = false
local function dismissTitle()
	if dismissed then
		return
	end
	dismissed = true
	TweenService:Create(titleOverlay, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(titleLabel, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
	TweenService:Create(startButton, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
	task.delay(0.55, function()
		titleOverlay:Destroy()
	end)
end
titleOverlay.MouseButton1Click:Connect(dismissTitle)
startButton.MouseButton1Click:Connect(dismissTitle)
task.delay(8, dismissTitle)
