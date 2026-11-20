-- GameUI: the whole Pasar Brainrot HUD — money panel, action buttons, hint bar,
-- toasts, upgrade and index panels, and the title overlay. Display font is
-- LuckiestGuy; labels use GothamBold/GothamBlack. Never Bungee: it is not a
-- Roblox font and breaks scripts that name it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")
local incomeValue = leaderstats:WaitForChild("Income")
local rebirthValue = leaderstats:WaitForChild("Rebirths")
local waveTimer = remotes:WaitForChild("WaveTimer")

local DARK = Color3.fromRGB(18, 10, 32)
local GOLD = Color3.fromRGB(255, 183, 3)
local PURPLE = Color3.fromRGB(157, 78, 221)
local CYAN = Color3.fromRGB(76, 201, 240)
local PINK = Color3.fromRGB(255, 77, 109)
local GREEN = Color3.fromRGB(120, 255, 140)
local WHITE = Color3.fromRGB(245, 240, 255)
local RED = Color3.fromRGB(255, 90, 90)

local TITLE_FONT = Enum.Font.LuckiestGuy
local LABEL_FONT = Enum.Font.GothamBold
local HEAVY_FONT = Enum.Font.GothamBlack

-- The same tuning the server runs on, copied here for the panels (the client
-- cannot require server modules).
local CHARACTERS = {
	{ Name = "Bakso Berlari", Rarity = "Common", Price = 50, Rate = 5, Color = Color3.fromRGB(158, 227, 125) },
	{ Name = "Es Teh Manis Terbang", Rarity = "Common", Price = 100, Rate = 8, Color = Color3.fromRGB(158, 227, 125) },
	{ Name = "Gorengan Galak", Rarity = "Rare", Price = 400, Rate = 20, Color = Color3.fromRGB(76, 201, 240) },
	{ Name = "Kucing Oren Ngamuk", Rarity = "Rare", Price = 800, Rate = 35, Color = Color3.fromRGB(76, 201, 240) },
	{ Name = "Ayam Geprek Terbang", Rarity = "Epic", Price = 2000, Rate = 60, Color = Color3.fromRGB(157, 78, 221) },
	{ Name = "Durian Meledak", Rarity = "Epic", Price = 4000, Rate = 100, Color = Color3.fromRGB(157, 78, 221) },
	{ Name = "Kopi Tubruk Raksasa", Rarity = "Legendary", Price = 10000, Rate = 180, Color = Color3.fromRGB(255, 183, 3) },
	{ Name = "Gerobak Bakso Terbang", Rarity = "Legendary", Price = 20000, Rate = 300, Color = Color3.fromRGB(255, 183, 3) },
	{ Name = "Nasi Padang Sejagat", Rarity = "Mythic", Price = 50000, Rate = 500, Color = Color3.fromRGB(255, 77, 109) },
}

local REBIRTH_NEEDS = { 25000, 150000, 750000, 3000000 }

local UPGRADES = {
	{ Id = "speed", Name = "Sepatu Kilat", Desc = "Lari lebih cepat", Costs = { 500, 2000, 6000 }, Attr = "SpeedLevel" },
	{ Id = "carry", Name = "Tangan Kedua", Desc = "Bawa 2 brainrot sekaligus", Costs = { 2500 }, Attr = "CarryCapacity" },
	{ Id = "income", Name = "Timbangan Emas", Desc = "+25% $/detik per level", Costs = { 1000, 4000, 12000 }, Attr = "IncomeLevel" },
}

local function compact(n)
	if n >= 1000000 then
		local s = string.format("%.1fJT", n / 1000000)
		return (s:gsub("%.0JT", "JT"))
	elseif n >= 1000 then
		local s = string.format("%.1fK", n / 1000)
		return (s:gsub("%.0K", "K"))
	else
		return tostring(math.floor(n))
	end
end

local function formatMoney(n)
	return "$" .. tostring(math.floor(n))
end

local function frame(parent, props)
	local f = Instance.new("Frame")
	for name, value in pairs(props) do
		f[name] = value
	end
	f.Parent = parent
	return f
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	for name, value in pairs(props) do
		l[name] = value
	end
	l.Parent = parent
	return l
end

local function button(parent, props)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	for name, value in pairs(props) do
		b[name] = value
	end
	b.Parent = parent
	return b
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local gui = Instance.new("ScreenGui")
gui.Name = "PasarBrainrotUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")

-- Money panel, top-centre (never top-left, where Roblox's menu buttons sit).
local moneyPanel = frame(gui, {
	Name = "MoneyPanel",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.fromOffset(360, 84),
	BackgroundColor3 = DARK,
	BackgroundTransparency = 0.15,
	BorderColor3 = GOLD,
	BorderSizePixel = 2,
})
corner(moneyPanel, 12)

local cashLabel = label(moneyPanel, {
	Name = "CashLabel",
	Position = UDim2.new(0, 0, 0, 4),
	Size = UDim2.new(1, 0, 0, 44),
	Font = TITLE_FONT,
	TextSize = 34,
	TextColor3 = GOLD,
	Text = "$250",
})
local cashScale = Instance.new("UIScale")
cashScale.Parent = cashLabel

local subLabel = label(moneyPanel, {
	Name = "SubLabel",
	Position = UDim2.new(0, 0, 0, 50),
	Size = UDim2.new(1, 0, 0, 26),
	Font = LABEL_FONT,
	TextSize = 15,
	TextColor3 = WHITE,
	Text = "$0/detik • x1 • REBIRTH 0 • Pemula Pasar",
})

local waveLabel = label(gui, {
	Name = "WaveLabel",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 104),
	Size = UDim2.fromOffset(360, 26),
	Font = TITLE_FONT,
	TextSize = 18,
	TextColor3 = PINK,
	Text = "GEROBAK TSUNAMI 1:15",
})

-- Upgrade panel: one row per upgrade, refreshed from player attributes.
local upgradePanel = frame(gui, {
	Name = "UpgradePanel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(460, 330),
	BackgroundColor3 = DARK,
	BorderColor3 = PURPLE,
	BorderSizePixel = 2,
	Visible = false,
})
corner(upgradePanel, 14)
label(upgradePanel, { Text = "UPGRADE", Font = TITLE_FONT, TextSize = 28, TextColor3 = GOLD, Position = UDim2.new(0, 0, 0, 10), Size = UDim2.new(1, 0, 0, 36) })
local upgradeClose = button(upgradePanel, { Text = "X", Font = HEAVY_FONT, TextSize = 20, TextColor3 = WHITE, BackgroundColor3 = Color3.fromRGB(120, 30, 30), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(36, 36) })
corner(upgradeClose, 8)

local refreshUpgradePanel -- assigned below; the buy buttons call it after a purchase
local upgradeRows = {}
for i, def in ipairs(UPGRADES) do
	local row = frame(upgradePanel, {
		Position = UDim2.new(0, 16, 0, 56 + (i - 1) * 88),
		Size = UDim2.new(1, -32, 0, 76),
		BackgroundColor3 = Color3.fromRGB(35, 22, 55),
		BorderSizePixel = 0,
	})
	corner(row, 10)
	label(row, { Text = def.Name, Font = TITLE_FONT, TextSize = 18, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(0.6, 0, 0, 26) })
	label(row, { Text = def.Desc, Font = LABEL_FONT, TextSize = 13, TextColor3 = Color3.fromRGB(200, 190, 220), TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 12, 0, 32), Size = UDim2.new(0.6, 0, 0, 22) })
	local levelLabel = label(row, { Text = "Lv 0/" .. #def.Costs, Font = LABEL_FONT, TextSize = 14, TextColor3 = CYAN, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 12, 0, 52), Size = UDim2.new(0.6, 0, 0, 20) })
	local buyButton = button(row, { Text = "BELI $" .. def.Costs[1], Font = HEAVY_FONT, TextSize = 16, TextColor3 = Color3.fromRGB(10, 40, 10), BackgroundColor3 = GREEN, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(120, 40) })
	corner(buyButton, 8)
	buyButton.MouseButton1Click:Connect(function()
		remotes.BuyUpgrade:FireServer(def.Id)
		task.delay(0.3, refreshUpgradePanel)
	end)
	upgradeRows[def.Id] = { levelLabel = levelLabel, buyButton = buyButton, def = def }
end

refreshUpgradePanel = function()
	for _, row in pairs(upgradeRows) do
		local def = row.def
		local level = 0
		if def.Id == "carry" then
			level = (player:GetAttribute("CarryCapacity") or 1) - 1
		else
			level = player:GetAttribute(def.Attr) or 0
		end
		row.levelLabel.Text = "Lv " .. level .. "/" .. #def.Costs
		if level >= #def.Costs then
			row.buyButton.Text = "MAX"
			row.buyButton.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
		else
			row.buyButton.Text = "BELI $" .. def.Costs[level + 1]
			row.buyButton.BackgroundColor3 = GREEN
		end
	end
end

-- Index panel: a 3x3 grid of character cards.
local indexPanel = frame(gui, {
	Name = "IndexPanel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(560, 380),
	BackgroundColor3 = DARK,
	BorderColor3 = CYAN,
	BorderSizePixel = 2,
	Visible = false,
})
corner(indexPanel, 14)
label(indexPanel, { Text = "INDEX BRAINROT", Font = TITLE_FONT, TextSize = 28, TextColor3 = GOLD, Position = UDim2.new(0, 0, 0, 10), Size = UDim2.new(1, 0, 0, 36) })
local indexClose = button(indexPanel, { Text = "X", Font = HEAVY_FONT, TextSize = 20, TextColor3 = WHITE, BackgroundColor3 = Color3.fromRGB(120, 30, 30), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(36, 36) })
corner(indexClose, 8)

local grid = frame(indexPanel, { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 56), Size = UDim2.new(1, -24, 1, -68), BorderSizePixel = 0 })
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.fromOffset(170, 100)
gridLayout.CellPadding = UDim2.fromOffset(8, 8)
gridLayout.Parent = grid
for _, char in ipairs(CHARACTERS) do
	local card = frame(grid, { BackgroundColor3 = Color3.fromRGB(35, 22, 55), BorderSizePixel = 0 })
	corner(card, 10)
	label(card, { Text = char.Name, Font = TITLE_FONT, TextSize = 14, TextColor3 = char.Color, Position = UDim2.new(0, 4, 0, 6), Size = UDim2.new(1, -8, 0, 40), TextWrapped = true })
	label(card, { Text = string.upper(char.Rarity) .. " • $" .. char.Rate .. "/detik", Font = LABEL_FONT, TextSize = 12, TextColor3 = WHITE, Position = UDim2.new(0, 4, 0, 48), Size = UDim2.new(1, -8, 0, 20) })
	label(card, { Text = "$" .. char.Price, Font = HEAVY_FONT, TextSize = 15, TextColor3 = GREEN, Position = UDim2.new(0, 4, 0, 70), Size = UDim2.new(1, -8, 0, 22) })
end

local function closePanels()
	upgradePanel.Visible = false
	indexPanel.Visible = false
end

local function toggleUpgrade()
	local show = not upgradePanel.Visible
	closePanels()
	upgradePanel.Visible = show
	if show then
		refreshUpgradePanel()
	end
end

local function toggleIndex()
	local show = not indexPanel.Visible
	closePanels()
	indexPanel.Visible = show
end

upgradeClose.MouseButton1Click:Connect(closePanels)
indexClose.MouseButton1Click:Connect(closePanels)

-- Music state: the Music script owns the Sound; this button only fires the toggle.
local musicOn = true
local musicButtons = {}

local function getMusicToggle()
	local toggle = ReplicatedStorage:FindFirstChild("MusicToggle")
	if not toggle then
		toggle = Instance.new("BindableEvent")
		toggle.Name = "MusicToggle"
		toggle.Parent = ReplicatedStorage
	end
	return toggle
end

-- The five actions, shared by the PC column and the touch menu.
local buttonSpecs = {
	{ key = "lock", text = "KUNCI LAPAK", color = Color3.fromRGB(0, 120, 110), action = function() remotes.LockBase:FireServer() end },
	{ key = "rebirth", text = "REBIRTH", color = Color3.fromRGB(150, 110, 10), action = function() remotes.RequestRebirth:FireServer() end },
	{ key = "upgrade", text = "UPGRADE", color = Color3.fromRGB(90, 50, 140), action = toggleUpgrade },
	{ key = "index", text = "INDEX (9)", color = Color3.fromRGB(60, 60, 80), action = toggleIndex },
	{ key = "music", text = "MUSIK: ON", color = Color3.fromRGB(40, 110, 70), action = function()
		musicOn = not musicOn
		getMusicToggle():Fire()
		for _, b in ipairs(musicButtons) do
			b.Text = musicOn and "MUSIK: ON" or "MUSIK: OFF"
		end
	end },
}

local function actionButton(parent, text, color, position, size)
	local b = button(parent, {
		Text = text,
		Font = TITLE_FONT,
		TextSize = 17,
		TextColor3 = WHITE,
		BackgroundColor3 = color,
		Position = position,
		Size = size,
		BorderSizePixel = 0,
	})
	corner(b, 10)
	return b
end

-- Touch devices without a keyboard get one small MENU pill instead of the
-- four-button stack, which would cover the jump button and camera area.
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local pcColumn = frame(gui, {
	Name = "ActionColumn",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 130),
	Size = UDim2.fromOffset(188, 272),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = not isTouch,
})

local pcButtons = {}
for i, spec in ipairs(buttonSpecs) do
	local b = actionButton(pcColumn, spec.text, spec.color, UDim2.new(0, 0, 0, (i - 1) * 56), UDim2.new(1, 0, 0, 48))
	b.MouseButton1Click:Connect(spec.action)
	pcButtons[spec.key] = b
	if spec.key == "music" then
		table.insert(musicButtons, b)
	end
end

local menuPanel
local function closeMenu()
	if menuPanel then
		menuPanel.Visible = false
	end
end

local menuPill = button(gui, {
	Name = "MenuPill",
	Text = "MENU",
	Font = TITLE_FONT,
	TextSize = 16,
	TextColor3 = WHITE,
	BackgroundColor3 = Color3.fromRGB(60, 60, 80),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 130),
	Size = UDim2.fromOffset(90, 36),
	BorderSizePixel = 0,
	Visible = isTouch,
})
corner(menuPill, 18)

menuPanel = frame(gui, {
	Name = "MenuPanel",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 174),
	Size = UDim2.fromOffset(188, 216),
	BackgroundColor3 = DARK,
	BackgroundTransparency = 0.1,
	BorderColor3 = PURPLE,
	BorderSizePixel = 2,
	Visible = false,
})
corner(menuPanel, 12)

local touchButtons = {}
for i, spec in ipairs(buttonSpecs) do
	local b = actionButton(menuPanel, spec.text, spec.color, UDim2.new(0, 10, 0, 10 + (i - 1) * 40), UDim2.new(1, -20, 0, 36))
	b.MouseButton1Click:Connect(function()
		spec.action()
		closeMenu()
	end)
	touchButtons[spec.key] = b
	if spec.key == "music" then
		table.insert(musicButtons, b)
	end
end

menuPill.MouseButton1Click:Connect(function()
	menuPanel.Visible = not menuPanel.Visible
end)

-- Carried / hint bar, bottom-centre.
local hintBar = frame(gui, {
	Name = "HintBar",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -12),
	Size = UDim2.fromOffset(560, 40),
	BackgroundColor3 = DARK,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
})
corner(hintBar, 10)
local hintLabel = label(hintBar, {
	Text = "Dekati brainrot di konveyor lalu tekan E untuk membeli",
	Font = LABEL_FONT,
	TextSize = 15,
	TextColor3 = WHITE,
	Size = UDim2.new(1, -16, 1, 0),
	Position = UDim2.new(0, 8, 0, 0),
})

-- Toasts, bottom-right: stacked cards that fade in, show for 3.5 seconds, fade out.
local toastHolder = frame(gui, {
	Name = "ToastHolder",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -12, 1, -60),
	Size = UDim2.fromOffset(340, 260),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
})
local toastLayout = Instance.new("UIListLayout")
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.Padding = UDim.new(0, 6)
toastLayout.Parent = toastHolder

local TOAST_COLORS = {
	good = GREEN,
	buy = GREEN,
	bad = RED,
	place = GOLD,
	rebirth = GOLD,
	steal = PINK,
	info = WHITE,
}

local function showToast(text, kind)
	local color = TOAST_COLORS[kind] or WHITE
	local toast = frame(toastHolder, {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.1,
		BorderColor3 = color,
		BorderSizePixel = 2,
	})
	corner(toast, 8)
	local toastLabel = label(toast, {
		Text = text,
		Font = LABEL_FONT,
		TextSize = 14,
		TextColor3 = color,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		TextWrapped = true,
	})
	toast.BackgroundTransparency = 1
	toastLabel.TextTransparency = 1
	TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 0.1 }):Play()
	TweenService:Create(toastLabel, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	task.delay(3.5, function()
		TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		local fade = TweenService:Create(toastLabel, TweenInfo.new(0.4), { TextTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		toast:Destroy()
	end)
end

-- Title overlay: fades out on click anywhere, or on its own after 8 seconds.
local overlay = frame(gui, {
	Name = "TitleOverlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(10, 5, 20),
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
})
label(overlay, { Text = "PASAR BRAINROT", Font = TITLE_FONT, TextSize = 64, TextColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.28, 0), Size = UDim2.new(1, 0, 0, 80) })
label(overlay, { Text = "Beli brainrot, bawa pulang, jadi kaya!", Font = LABEL_FONT, TextSize = 20, TextColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0, 0.28, 84), Size = UDim2.new(1, 0, 0, 30) })
label(overlay, { Text = "WASD jalan • E beli / ambil • Tombol di kanan: kunci, rebirth, upgrade, index", Font = LABEL_FONT, TextSize = 15, TextColor3 = Color3.fromRGB(200, 190, 220), AnchorPoint = Vector2.new(0.5, 0, 0.28, 122), Size = UDim2.new(1, 0, 0, 26) })
local startButton = button(overlay, { Text = "MULAI MAIN", Font = TITLE_FONT, TextSize = 24, TextColor3 = Color3.fromRGB(30, 20, 0), BackgroundColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.28, 170), Size = UDim2.fromOffset(240, 56), BorderSizePixel = 0 })
corner(startButton, 12)

local overlayGone = false
local function dismissOverlay()
	if overlayGone then
		return
	end
	overlayGone = true
	local fade = TweenService:Create(overlay, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
	fade:Play()
	for _, child in ipairs(overlay:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			TweenService:Create(child, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		end
	end
	fade.Completed:Wait()
	overlay:Destroy()
end
startButton.MouseButton1Click:Connect(dismissOverlay)
local overlayClick = button(overlay, { Text = "", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 0 })
overlayClick.MouseButton1Click:Connect(dismissOverlay)
task.delay(8, dismissOverlay)

-- Live updates from leaderstats, player attributes and the wave timer.
local function refreshMoneyLine()
	local income = incomeValue.Value
	local mult = player:GetAttribute("Multiplier") or 1
	local rebirths = rebirthValue.Value
	local title = player:GetAttribute("RebirthTitle") or "Pemula Pasar"
	local multText
	if mult == math.floor(mult) then
		multText = "x" .. tostring(math.floor(mult))
	else
		multText = "x" .. string.format("%.2f", mult)
	end
	subLabel.Text = "$" .. income .. "/detik • " .. multText .. " • REBIRTH " .. rebirths .. " • " .. title
end

local function refreshRebirthButton()
	local rebirths = rebirthValue.Value
	local earned = player:GetAttribute("TotalEarned") or 0
	local text = "REBIRTH MAX"
	if rebirths < #REBIRTH_NEEDS then
		text = "REBIRTH " .. compact(earned) .. "/" .. compact(REBIRTH_NEEDS[rebirths + 1])
	end
	if pcButtons.rebirth then
		pcButtons.rebirth.Text = text
	end
	if touchButtons.rebirth then
		touchButtons.rebirth.Text = text
	end
end

local function refreshHint()
	local carried = player:GetAttribute("CarriedNames") or ""
	if carried ~= "" then
		hintLabel.Text = "MEMBAWA: " .. carried .. " — bawa ke lapakmu untuk menaruh!"
		hintLabel.TextColor3 = GOLD
	else
		hintLabel.Text = "Dekati brainrot di konveyor lalu tekan E untuk membeli"
		hintLabel.TextColor3 = WHITE
	end
end

local function refreshWave()
	local seconds = waveTimer.Value
	waveLabel.Text = "GEROBAK TSUNAMI " .. math.floor(seconds / 60) .. ":" .. string.format("%02d", seconds % 60)
	waveLabel.TextColor3 = seconds < 15 and RED or PINK
end

cashValue.Changed:Connect(function()
	cashLabel.Text = formatMoney(cashValue.Value)
	TweenService:Create(cashScale, TweenInfo.new(0.12), { Scale = 1.12 }):Play()
	task.delay(0.12, function()
		TweenService:Create(cashScale, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end)
end)
incomeValue.Changed:Connect(refreshMoneyLine)
rebirthValue.Changed:Connect(function()
	refreshMoneyLine()
	refreshRebirthButton()
end)
player:GetAttributeChangedSignal("Multiplier"):Connect(refreshMoneyLine)
player:GetAttributeChangedSignal("TotalEarned"):Connect(refreshRebirthButton)
player:GetAttributeChangedSignal("RebirthTitle"):Connect(refreshMoneyLine)
player:GetAttributeChangedSignal("CarriedNames"):Connect(refreshHint)
waveTimer.Changed:Connect(refreshWave)

-- Lock button countdown, refreshed twice a second.
task.spawn(function()
	while true do
		task.wait(0.5)
		local lockedUntil = player:GetAttribute("BaseLockedUntil") or 0
		local remaining = lockedUntil - os.time()
		local text = "KUNCI LAPAK"
		if remaining > 0 then
			text = "TERKUNCI " .. remaining .. " dtk"
		end
		if pcButtons.lock then
			pcButtons.lock.Text = text
		end
		if touchButtons.lock then
			touchButtons.lock.Text = text
		end
	end
end)

remotes.Notify.OnClientEvent:Connect(function(text, kind)
	showToast(text, kind)
end)

cashLabel.Text = formatMoney(cashValue.Value)
refreshMoneyLine()
refreshRebirthButton()
refreshHint()
refreshWave()
