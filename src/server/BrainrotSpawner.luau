-- Pasar Brainrot: the cast and the conveyor.
-- Builds each of the nine original characters from plain Parts (no uploaded
-- assets, so the game looks the same in every Studio), walks them along the
-- conveyor belt, and sells them to players who press E. A bought brainrot is
-- handed to BaseService to carry home; a dropped one comes back here.

local BrainrotSpawner = {}

local Config = require(script.Parent.Config)
local MoneyService = require(script.Parent.MoneyService)
local BaseService = require(script.Parent.BaseService)

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local conveyorFolder = nil
local active = {}

-- Part helpers. Models are built around the origin (0,0,0) and moved with
-- PivotTo, so every offset below is relative to the model's centre.
local function addPart(model, name, size, offset, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = offset
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = model
	return part
end

local function addCylinder(model, name, radius, height, offset, color, axis, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(height, radius * 2, radius * 2)
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local cf = CFrame.new(offset)
	if axis == "Y" then
		cf *= CFrame.Angles(0, 0, math.rad(90))
	elseif axis == "Z" then
		cf *= CFrame.Angles(0, math.rad(90), 0)
	end
	part.CFrame = cf
	part.Parent = model
	return part
end

local function addEyes(model, y, z, spacing, size)
	size = size or 0.5
	addPart(model, "EyeL", Vector3.new(size, size, size), Vector3.new(-spacing, y, z), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "EyeR", Vector3.new(size, size, size), Vector3.new(spacing, y, z), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
end

local function addWings(model, y, color, span)
	span = span or 1.5
	local left = addPart(model, "WingL", Vector3.new(1.4, 0.15, 0.9), Vector3.new(-span, y, 0), color)
	left.CFrame = CFrame.new(-span, y, 0) * CFrame.Angles(0, 0, math.rad(20))
	local right = addPart(model, "WingR", Vector3.new(1.4, 0.15, 0.9), Vector3.new(span, y, 0), color)
	right.CFrame = CFrame.new(span, y, 0) * CFrame.Angles(0, 0, math.rad(-20))
end

-- One builder per character. Each names its main body part "Body", which
-- becomes the model's PrimaryPart. Front is +Z in model space.
local BUILDERS = {}

BUILDERS.bakso = function(model, def)
	addPart(model, "Body", Vector3.new(2.2, 2.2, 2.2), Vector3.new(0, 0, 0), def.color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "LegL", Vector3.new(0.4, 0.8, 0.4), Vector3.new(-0.5, -1.3, 0.2), Color3.fromRGB(90, 60, 35))
	addPart(model, "LegR", Vector3.new(0.4, 0.8, 0.4), Vector3.new(0.5, -1.3, 0.2), Color3.fromRGB(90, 60, 35))
	addCylinder(model, "Headband", 1.15, 0.28, Vector3.new(0, 0.7, 0), Color3.fromRGB(220, 50, 50), "Y")
	addEyes(model, 0.3, 0.95, 0.45)
end

BUILDERS.teh = function(model, def)
	addCylinder(model, "Body", 0.95, 2.4, Vector3.new(0, 0, 0), Color3.fromRGB(255, 210, 120), "Y", Enum.Material.Glass, 0.25)
	addCylinder(model, "Tea", 0.78, 1.8, Vector3.new(0, -0.2, 0), Color3.fromRGB(235, 150, 40), "Y")
	addPart(model, "Ice1", Vector3.new(0.5, 0.5, 0.5), Vector3.new(-0.3, 0.8, 0.2), Color3.fromRGB(220, 240, 255), Enum.Material.Glass)
	addPart(model, "Ice2", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0.35, 0.7, -0.2), Color3.fromRGB(220, 240, 255), Enum.Material.Glass)
	local straw = addCylinder(model, "Straw", 0.12, 2.4, Vector3.new(0.4, 1.2, 0), Color3.fromRGB(230, 60, 60), "Y")
	straw.CFrame = CFrame.new(0.4, 1.2, 0) * CFrame.Angles(0, 0, math.rad(-18))
	addWings(model, 0.2, Color3.fromRGB(255, 255, 255))
	addEyes(model, 0.3, 0.85, 0.4)
end

BUILDERS.gorengan = function(model, def)
	addPart(model, "Body", Vector3.new(2.4, 1.7, 1.7), Vector3.new(0, -0.2, 0), def.color)
	addPart(model, "TopBlob", Vector3.new(1.8, 1.4, 1.5), Vector3.new(0, 0.8, 0), Color3.fromRGB(250, 205, 80), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local browL = addPart(model, "BrowL", Vector3.new(0.7, 0.16, 0.16), Vector3.new(-0.5, 0.65, 0.9), Color3.fromRGB(30, 20, 10))
	browL.CFrame = CFrame.new(-0.5, 0.65, 0.9) * CFrame.Angles(0, 0, math.rad(25))
	local browR = addPart(model, "BrowR", Vector3.new(0.7, 0.16, 0.16), Vector3.new(0.5, 0.65, 0.9), Color3.fromRGB(30, 20, 10))
	browR.CFrame = CFrame.new(0.5, 0.65, 0.9) * CFrame.Angles(0, 0, math.rad(-25))
	addEyes(model, 0.25, 0.9, 0.5)
	addPart(model, "ArmL", Vector3.new(0.35, 1.1, 0.35), Vector3.new(-1.4, -0.3, 0), Color3.fromRGB(230, 175, 55))
	addPart(model, "ArmR", Vector3.new(0.35, 1.1, 0.35), Vector3.new(1.4, -0.3, 0), Color3.fromRGB(230, 175, 55))
end

BUILDERS.kucing = function(model, def)
	addPart(model, "Body", Vector3.new(2.4, 2.4, 2.4), Vector3.new(0, 0, 0), def.color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local earL = Instance.new("WedgePart")
	earL.Name = "EarL"
	earL.Size = Vector3.new(0.8, 0.9, 0.7)
	earL.Position = Vector3.new(-0.7, 1.4, 0)
	earL.Color = def.color
	earL.Anchored = true
	earL.CanCollide = false
	earL.Parent = model
	local earR = Instance.new("WedgePart")
	earR.Name = "EarR"
	earR.Size = Vector3.new(0.8, 0.9, 0.7)
	earR.Position = Vector3.new(0.7, 1.4, 0)
	earR.Color = def.color
	earR.Anchored = true
	earR.CanCollide = false
	earR.Parent = model
	addPart(model, "Tail1", Vector3.new(0.35, 1.2, 0.35), Vector3.new(0, 0.6, -1.3), def.color)
	local tail2 = addPart(model, "Tail2", Vector3.new(0.35, 1.0, 0.35), Vector3.new(0, 1.5, -1.5), def.color)
	tail2.CFrame = CFrame.new(0, 1.5, -1.5) * CFrame.Angles(math.rad(35), 0, 0)
	addPart(model, "Nose", Vector3.new(0.3, 0.25, 0.2), Vector3.new(0, -0.05, 1.2), Color3.fromRGB(255, 150, 180))
	addEyes(model, 0.35, 1.05, 0.5, 0.54)
end

BUILDERS.geprek = function(model, def)
	addPart(model, "Body", Vector3.new(2.6, 2.6, 2.6), Vector3.new(0, 0, 0), def.color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addWings(model, 0.1, Color3.fromRGB(200, 150, 90), 1.8)
	local beak = Instance.new("WedgePart")
	beak.Name = "Beak"
	beak.Size = Vector3.new(0.6, 0.5, 0.9)
	beak.Position = Vector3.new(0, -0.15, 1.4)
	beak.Color = Color3.fromRGB(255, 160, 30)
	beak.Anchored = true
	beak.CanCollide = false
	beak.CFrame = CFrame.new(0, -0.15, 1.4) * CFrame.Angles(math.rad(90), 0, 0)
	beak.Parent = model
	addPart(model, "Comb", Vector3.new(0.4, 0.7, 1.0), Vector3.new(0, 1.5, 0.1), Color3.fromRGB(220, 40, 40))
	addPart(model, "FootL", Vector3.new(0.4, 0.4, 0.7), Vector3.new(-0.5, -1.4, 0.3), Color3.fromRGB(255, 160, 30))
	addPart(model, "FootR", Vector3.new(0.4, 0.4, 0.7), Vector3.new(0.5, -1.4, 0.3), Color3.fromRGB(255, 160, 30))
	addEyes(model, 0.5, 1.1, 0.55)
end

BUILDERS.durian = function(model, def)
	addPart(model, "Body", Vector3.new(3.0, 3.0, 3.0), Vector3.new(0, 0, 0), def.color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	-- Bumpy shell: eight knobs around the body read as durian spikes.
	local knobs = {
		Vector3.new(0, 1.5, 0), Vector3.new(1.4, 0.5, 0), Vector3.new(-1.4, 0.5, 0),
		Vector3.new(0, 0.5, 1.4), Vector3.new(0, 0.5, -1.4), Vector3.new(1.0, -0.9, 1.0),
		Vector3.new(-1.0, -0.9, -1.0), Vector3.new(0, -1.5, 0),
	}
	for i, pos in ipairs(knobs) do
		addPart(model, "Knob" .. i, Vector3.new(0.55, 0.55, 0.55), pos, Color3.fromRGB(70, 130, 45), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
	addCylinder(model, "Fuse", 0.1, 0.9, Vector3.new(0, 1.9, 0), Color3.fromRGB(120, 85, 50), "Y")
	addPart(model, "Spark", Vector3.new(0.4, 0.4, 0.4), Vector3.new(0, 2.4, 0), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, Enum.PartType.Ball)
	addEyes(model, 0.3, 1.4, 0.6, 0.57)
end

BUILDERS.kopi = function(model, def)
	addCylinder(model, "Body", 1.5, 3.2, Vector3.new(0, 0, 0), def.color, "Y")
	addCylinder(model, "CoffeeTop", 1.35, 0.25, Vector3.new(0, 1.5, 0), Color3.fromRGB(140, 90, 45), "Y")
	addCylinder(model, "Saucer", 2.0, 0.25, Vector3.new(0, -1.7, 0), Color3.fromRGB(240, 230, 210), "Y")
	addCylinder(model, "Handle", 0.16, 1.6, Vector3.new(1.65, 0.2, 0), def.color, "Y")
	addPart(model, "HandleTop", Vector3.new(0.5, 0.3, 0.3), Vector3.new(1.5, 0.95, 0), def.color)
	addPart(model, "HandleBottom", Vector3.new(0.5, 0.3, 0.3), Vector3.new(1.5, -0.55, 0), def.color)
	local steam1 = addPart(model, "Steam1", Vector3.new(0.7, 0.7, 0.7), Vector3.new(-0.4, 2.3, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	steam1.Transparency = 0.5
	local steam2 = addPart(model, "Steam2", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0.4, 2.8, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	steam2.Transparency = 0.6
	addEyes(model, 0.3, 1.4, 0.6, 0.6)
end

BUILDERS.gerobak = function(model, def)
	addPart(model, "Body", Vector3.new(3.6, 1.5, 2.2), Vector3.new(0, 0, 0), def.color, Enum.Material.WoodPlanks)
	addCylinder(model, "WheelL", 0.7, 0.4, Vector3.new(-1.2, -1.0, 1.25), Color3.fromRGB(40, 35, 45), "Z")
	addCylinder(model, "WheelR", 0.7, 0.4, Vector3.new(-1.2, -1.0, -1.25), Color3.fromRGB(40, 35, 45), "Z")
	addCylinder(model, "WheelL2", 0.7, 0.4, Vector3.new(1.2, -1.0, 1.25), Color3.fromRGB(40, 35, 45), "Z")
	addCylinder(model, "WheelR2", 0.7, 0.4, Vector3.new(1.2, -1.0, -1.25), Color3.fromRGB(40, 35, 45), "Z")
	addCylinder(model, "UmbrellaPole", 0.12, 2.4, Vector3.new(0, 1.9, 0), Color3.fromRGB(120, 90, 60), "Y")
	addCylinder(model, "Umbrella", 2.2, 0.2, Vector3.new(0, 3.1, 0), Color3.fromRGB(230, 60, 60), "Y")
	addPart(model, "BaksoBall", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0.8, 1.3, 0), Color3.fromRGB(150, 100, 60), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addWings(model, 0.4, Color3.fromRGB(255, 255, 255), 2.3)
	addEyes(model, 0.2, 1.15, 0.7, 0.54)
end

BUILDERS.padang = function(model, def)
	addCylinder(model, "Plate", 2.1, 0.3, Vector3.new(0, -1.2, 0), Color3.fromRGB(245, 245, 245), "Y")
	addCylinder(model, "GoldRing", 2.3, 0.15, Vector3.new(0, -1.45, 0), Color3.fromRGB(255, 183, 3), "Y", Enum.Material.Neon)
	addPart(model, "Body", Vector3.new(2.6, 1.7, 2.6), Vector3.new(0, -0.3, 0), Color3.fromRGB(255, 250, 235), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "Rendang1", Vector3.new(0.7, 0.6, 0.7), Vector3.new(-0.6, 0.6, 0.3), Color3.fromRGB(110, 60, 30))
	addPart(model, "Rendang2", Vector3.new(0.7, 0.6, 0.7), Vector3.new(0.5, 0.65, -0.3), Color3.fromRGB(110, 60, 30))
	addPart(model, "Rendang3", Vector3.new(0.6, 0.5, 0.6), Vector3.new(0.1, 0.7, 0.5), Color3.fromRGB(130, 70, 35))
	addCylinder(model, "Chili", 0.14, 1.0, Vector3.new(0.9, 0.7, 0.4), Color3.fromRGB(220, 30, 30), "Y")
	for i = 1, 3 do
		local angle = (i - 1) * math.rad(120)
		addPart(model, "Sparkle" .. i, Vector3.new(0.35, 0.35, 0.35), Vector3.new(math.cos(angle) * 2.5, 0.6, math.sin(angle) * 2.5), Color3.fromRGB(255, 220, 80), Enum.Material.Neon, Enum.PartType.Ball)
	end
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 200, 80)
	glow.Range = 12
	glow.Brightness = 2
	glow.Parent = model
	addEyes(model, 0.1, 1.25, 0.55, 0.54)
end

-- Name + rarity + $/second label floating above the character.
local function attachNameLabel(model, def)
	local primary = model.PrimaryPart
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameLabel"
	gui.Adornee = primary
	gui.Size = UDim2.fromOffset(170, 66)
	gui.StudsOffset = Vector3.new(0, def.size / 2 + 1.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model
	local rarity = Config.RARITIES[def.rarity]
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLine"
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.name
	nameLabel.TextColor3 = rarity.color
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.LuckiestGuy
	nameLabel.TextStrokeTransparency = 0.1
	nameLabel.Parent = gui
	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLine"
	rateLabel.Position = UDim2.new(0, 0, 0.4, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = def.rarity:upper() .. "  •  $" .. def.rate .. "/detik"
	rateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rateLabel.TextSize = 15
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.TextStrokeTransparency = 0.1
	rateLabel.Parent = gui
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLine"
	priceLabel.Position = UDim2.new(0, 0, 0.7, 0)
	priceLabel.Size = UDim2.new(1, 0, 0.3, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "BELI $" .. def.price
	priceLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	priceLabel.TextSize = 16
	priceLabel.Font = Enum.Font.GothamBlack
	priceLabel.TextStrokeTransparency = 0.1
	priceLabel.Parent = gui
	return gui
end

local function findCharacterDef(key)
	for _, def in ipairs(Config.CHARACTERS) do
		if def.key == key then
			return def
		end
	end
	return Config.CHARACTERS[1]
end

local function buildCharacterModel(def)
	local model = Instance.new("Model")
	model.Name = def.name
	BUILDERS[def.key](model, def)
	-- Scale the whole model up 1.4x so the 3D shape reads clearly in the
	-- bright sunset scene. Parts are still at the model origin, so scaling
	-- each part's size and its offset from the origin keeps every rotation
	-- intact.
	local SCALE = 1.4
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * SCALE
			part.CFrame = CFrame.new(part.Position * SCALE) * (part.CFrame - part.Position)
		elseif part:IsA("PointLight") then
			part.Range = part.Range * SCALE
		end
	end
	-- Measure the model's real extents AFTER scaling. The nominal def.size
	-- is only a rough body height: legs, wheels and plates stick out below
	-- the body, so the true bounding box is taller and its centre sits
	-- below the model origin. Placement must rest the bbox BOTTOM on the
	-- surface, so measure the pivot-to-bbox-bottom distance (BottomOffset)
	-- and the pivot-to-bbox-top distance (TopOffset). The pivot is the
	-- PrimaryPart (Body at the model origin), NOT the bbox centre, so
	-- half the bbox height is the wrong number: it sinks small characters
	-- into the belt and floats large ones above it.
	local body = model:FindFirstChild("Body")
	local bboxCFrame, bboxSize = model:GetBoundingBox()
	local bboxMinY = bboxCFrame.Y - bboxSize.Y / 2
	local bboxMaxY = bboxCFrame.Y + bboxSize.Y / 2
	local pivotY = body and body.Position.Y or 0
	model:SetAttribute("BottomOffset", pivotY - bboxMinY)
	model:SetAttribute("TopOffset", bboxMaxY - pivotY)
	-- Neon glow ring in the rarity colour, added after the scale pass so it
	-- keeps its own size. Its centre sits 0.2 above the bbox bottom, so
	-- it always reads as a halo on the belt or pedestal, never sunk inside
	-- it, and doubles as a rarity indicator at a glance.
	addCylinder(model, "GlowRing", def.size * 0.62, 0.3, Vector3.new(0, bboxMinY + 0.2, 0), Config.RARITIES[def.rarity].color, "Y", Enum.Material.Neon)
	model.PrimaryPart = model:FindFirstChild("Body")
	model:SetAttribute("CharKey", def.key)
	model:SetAttribute("CharName", def.name)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Price", def.price)
	model:SetAttribute("Rate", def.rate)
	model:SetAttribute("Size", def.size)
	model:SetAttribute("State", "conveyor")
	model:SetAttribute("Owner", "")
	attachNameLabel(model, def)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "BELI $" .. def.price
	prompt.ObjectText = def.name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	return model
end

-- One prompt per brainrot for its whole life: on the conveyor it buys, on a
-- lapak it takes (steals from others, picks up your own).
local function onPromptTriggered(player, model)
	local state = model:GetAttribute("State")
	if state == "conveyor" then
		BrainrotSpawner.tryBuyBrainrot(player, model)
	elseif state == "placed" then
		BaseService.tryTakeBrainrot(player, model)
	end
end

local function pickCharacter()
	local total = 0
	for _, def in ipairs(Config.CHARACTERS) do
		total += def.weight
	end
	local roll = math.random(1, total)
	local acc = 0
	for _, def in ipairs(Config.CHARACTERS) do
		acc += def.weight
		if roll <= acc then
			return def
		end
	end
	return Config.CHARACTERS[1]
end

function BrainrotSpawner.spawnBrainrot(startX)
	local def = pickCharacter()
	local model = buildCharacterModel(def)
	local x = startX or Config.CONVEYOR.startX
	model:PivotTo(CFrame.new(x, Config.CONVEYOR.beltTopY + model:GetAttribute("BottomOffset") + 0.2, Config.CONVEYOR.z) * CFrame.Angles(0, math.rad(90), 0))
	model.Parent = conveyorFolder
	local prompt = model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(function(player)
			onPromptTriggered(player, model)
		end)
	end
	active[model] = { def = def, x = x, phase = math.random() * 6.28 }
	return model
end

local function getNotifyRemote()
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")
end

local function notify(player, text, kind)
	getNotifyRemote():FireClient(player, text, kind)
end

-- Buys the brainrot off the conveyor: pay, then carry it home.
function BrainrotSpawner.tryBuyBrainrot(player, model)
	local record = active[model]
	if not record then
		return
	end
	local def = record.def
	if #BaseService.getCarried(player) >= BaseService.getCarryCapacity(player) then
		notify(player, "Tanganmu penuh! Upgrade kapasitas dulu.", "bad")
		return
	end
	if not MoneyService.spendCash(player, def.price) then
		notify(player, "Uang tidak cukup! Butuh $" .. def.price, "bad")
		return
	end
	active[model] = nil
	BaseService.carryBrainrot(player, model)
	notify(player, "Membeli " .. def.name .. "! Bawa ke lapakmu.", "buy")
end

-- A dropped brainrot (tsunami, player left) walks the conveyor again as a
-- free spawn anyone can buy.
function BrainrotSpawner.returnToConveyor(model)
	local def = findCharacterDef(model:GetAttribute("CharKey"))
	model:SetAttribute("State", "conveyor")
	model:SetAttribute("Owner", "")
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
	local prompt = model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.ActionText = "BELI $" .. def.price
		prompt.Enabled = true
	end
	local label = model:FindFirstChild("NameLabel")
	if label then
		local priceLine = label:FindFirstChild("PriceLine")
		if priceLine then
			priceLine.Visible = true
		end
	end
	model:PivotTo(CFrame.new(Config.CONVEYOR.startX, Config.CONVEYOR.beltTopY + model:GetAttribute("BottomOffset") + 0.2, Config.CONVEYOR.z) * CFrame.Angles(0, math.rad(90), 0))
	active[model] = { def = def, x = Config.CONVEYOR.startX, phase = math.random() * 6.28 }
end

function BrainrotSpawner.start()
	conveyorFolder = Instance.new("Folder")
	conveyorFolder.Name = "ConveyorBrainrots"
	conveyorFolder.Parent = Workspace
	-- Walk every conveyor brainrot toward the far end, with a bob and wobble.
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for model, record in pairs(active) do
			if not model.Parent then
				active[model] = nil
			else
				record.x += Config.CONVEYOR.speed * dt
				if record.x >= Config.CONVEYOR.endX then
					active[model] = nil
					model:Destroy()
				else
					local bob = math.sin(now * 4 + record.phase) * 0.15
					local wobble = math.sin(now * 6 + record.phase) * 0.08
					model:PivotTo(CFrame.new(record.x, Config.CONVEYOR.beltTopY + model:GetAttribute("BottomOffset") + 0.2 + bob, Config.CONVEYOR.z) * CFrame.Angles(0, math.rad(90), wobble))
				end
			end
		end
	end)
	-- Spawn a fresh brainrot every few seconds, up to the cap.
	task.spawn(function()
		while true do
			task.wait(Config.SPAWN_INTERVAL)
			local count = 0
			for _ in pairs(active) do
				count += 1
			end
			if count < Config.MAX_ON_CONVEYOR then
				BrainrotSpawner.spawnBrainrot()
			end
		end
	end)
	-- Pre-seed the belt so the market is alive from the first second.
	BrainrotSpawner.spawnBrainrot(-72)
	BrainrotSpawner.spawnBrainrot(-45)
	BrainrotSpawner.spawnBrainrot(-18)
	BrainrotSpawner.spawnBrainrot(9)
end

return BrainrotSpawner
