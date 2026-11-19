-- BrainrotSpawner.luau
-- Builds the nine snack characters from plain parts, walks them down the
-- conveyor belt, and sells them. Each character is a Model built around the
-- origin facing +Z, then scaled up 1.4x so the shapes read clearly from
-- across the market.
--
-- Placement and carrying never trust the nominal body height: after scaling,
-- the model's real bounding box is measured and the distances from the pivot
-- (the Body part) down to the bottom and up to the top are stored as
-- attributes. Legs, wheels and plates stick out below the body, so only the
-- measured offsets put a model flush on a surface.
--
-- One proximity prompt lives on each brainrot for its whole life: on the
-- belt it buys, on a lapak it takes (steal from others, pick up your own).
-- The lapak service is injected through init() so this module never requires
-- it back (that would be a require cycle).

local Config = require(script.Parent.Config)
local MoneyService = require(script.Parent.MoneyService)

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")

local Spawner = {}

local SCALE = 1.4
local handlers = {} -- canCarry, carry, take: set by init()
local active = {} -- belt entries: { Model, X, Phase, BaseY }
local activeByModel = {} -- [model] = belt entry

-- A part of a character, placed relative to the model origin. Characters are
-- decorative, so their parts never collide.
local function addPart(model, name, size, offset, color, material, shape, rotation)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	if rotation then
		part.CFrame = CFrame.new(offset) * rotation
	else
		part.CFrame = CFrame.new(offset)
	end
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	part.Anchored = true
	part.CanCollide = false
	part.Parent = model
	return part
end

-- A vertical cylinder. A cylinder part's axis runs along X, so standing one
-- up means turning it 90 degrees around Z.
local function addCylinderUp(model, name, radius, height, offset, color, material, transparency)
	local part = addPart(model, name, Vector3.new(height, radius * 2, radius * 2), offset, color, material, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.rad(90)))
	if transparency then
		part.Transparency = transparency
	end
	return part
end

-- Two black ball eyes, level with each other on the face.
local function addEyes(model, y, z, halfGap, size)
	addPart(model, "EyeLeft", Vector3.new(size, size, size), Vector3.new(-halfGap, y, z), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "EyeRight", Vector3.new(size, size, size), Vector3.new(halfGap, y, z), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
end

-- A pair of flat white wings, angled slightly upward, one on each side.
local function addWings(model, xOut, y, sizeX, sizeZ, tilt)
	addPart(model, "WingLeft", Vector3.new(sizeX, 0.12, sizeZ), Vector3.new(-xOut, y, 0), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic, nil, CFrame.Angles(0, 0, math.rad(tilt)))
	addPart(model, "WingRight", Vector3.new(sizeX, 0.12, sizeZ), Vector3.new(xOut, y, 0), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic, nil, CFrame.Angles(0, 0, math.rad(-tilt)))
end

-- The nine builders. Each one's first part is the "Body", which becomes the
-- model's PrimaryPart. All offsets are pre-scale, relative to the origin.
local builders = {}

builders.bakso = function(model, def)
	addPart(model, "Body", Vector3.new(2.2, 2.2, 2.2), Vector3.new(0, 0, 0), def.Color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "LegLeft", Vector3.new(0.4, 0.8, 0.4), Vector3.new(-0.5, -1.3, 0), Color3.fromRGB(60, 45, 35))
	addPart(model, "LegRight", Vector3.new(0.4, 0.8, 0.4), Vector3.new(0.5, -1.3, 0), Color3.fromRGB(60, 45, 35))
	addCylinderUp(model, "Headband", 1.15, 0.28, Vector3.new(0, 0.7, 0), Color3.fromRGB(220, 40, 40))
	addEyes(model, 0.3, 0.95, 0.45, 0.5)
end

builders.teh = function(model, def)
	addCylinderUp(model, "Body", 0.95, 2.4, Vector3.new(0, 0, 0), Color3.fromRGB(240, 220, 130), Enum.Material.Glass, 0.25)
	addCylinderUp(model, "Tea", 0.78, 1.8, Vector3.new(0, -0.2, 0), Color3.fromRGB(230, 140, 40))
	addPart(model, "IceLeft", Vector3.new(0.6, 0.6, 0.6), Vector3.new(-0.35, 0.85, 0), Color3.fromRGB(230, 245, 255), Enum.Material.Glass, nil, CFrame.Angles(0, math.rad(20), 0))
	addPart(model, "IceRight", Vector3.new(0.6, 0.6, 0.6), Vector3.new(0.35, 0.85, 0), Color3.fromRGB(230, 245, 255), Enum.Material.Glass, nil, CFrame.Angles(0, math.rad(-15), 0))
	local straw = addPart(model, "Straw", Vector3.new(2, 0.24, 0.24), Vector3.new(0.55, 1.1, 0), Color3.fromRGB(220, 40, 40), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.rad(108)))
	straw.TopSurface = Enum.SurfaceType.Smooth
	addWings(model, 1.15, 0.2, 1, 0.8, 20)
	addEyes(model, 0.3, 0.85, 0.4, 0.45)
end

builders.gorengan = function(model, def)
	addPart(model, "Body", Vector3.new(2.4, 1.7, 1.7), Vector3.new(0, -0.2, 0), def.Color)
	addPart(model, "TopBlob", Vector3.new(1.6, 1.6, 1.6), Vector3.new(0, 0.9, 0), Color3.fromRGB(250, 215, 120), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "BrowLeft", Vector3.new(0.7, 0.18, 0.2), Vector3.new(-0.5, 0.75, 0.85), Color3.fromRGB(60, 40, 20), Enum.Material.SmoothPlastic, nil, CFrame.Angles(0, 0, math.rad(25)))
	addPart(model, "BrowRight", Vector3.new(0.7, 0.18, 0.2), Vector3.new(0.5, 0.75, 0.85), Color3.fromRGB(60, 40, 20), Enum.Material.SmoothPlastic, nil, CFrame.Angles(0, 0, math.rad(-25)))
	addEyes(model, 0.35, 0.9, 0.5, 0.5)
	addPart(model, "ArmLeft", Vector3.new(0.9, 0.35, 0.35), Vector3.new(-1.5, -0.3, 0), def.Color, Enum.Material.SmoothPlastic, nil, CFrame.Angles(0, 0, math.rad(30)))
	addPart(model, "ArmRight", Vector3.new(0.9, 0.35, 0.35), Vector3.new(1.5, -0.3, 0), def.Color, Enum.Material.SmoothPlastic, nil, CFrame.Angles(0, 0, math.rad(-30)))
end

builders.kucing = function(model, def)
	addPart(model, "Body", Vector3.new(2.4, 2.4, 2.4), Vector3.new(0, 0, 0), def.Color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "EarLeft", Vector3.new(0.7, 0.8, 0.5), Vector3.new(-0.7, 1.4, 0), def.Color, Enum.Material.SmoothPlastic, Enum.PartType.Wedge)
	addPart(model, "EarRight", Vector3.new(0.7, 0.8, 0.5), Vector3.new(0.7, 1.4, 0), def.Color, Enum.Material.SmoothPlastic, Enum.PartType.Wedge)
	addPart(model, "TailLow", Vector3.new(0.35, 1, 0.35), Vector3.new(0, 0.6, -1.3), def.Color, Enum.Material.SmoothPlastic, nil, CFrame.Angles(math.rad(-30), 0, 0))
	addPart(model, "TailHigh", Vector3.new(0.35, 0.9, 0.35), Vector3.new(0, 1.4, -1.6), def.Color, Enum.Material.SmoothPlastic, nil, CFrame.Angles(math.rad(20), 0, 0))
	addPart(model, "Nose", Vector3.new(0.3, 0.3, 0.3), Vector3.new(0, 0.05, 1.2), Color3.fromRGB(255, 150, 180), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addEyes(model, 0.35, 1.05, 0.5, 0.54)
end

builders.geprek = function(model, def)
	addPart(model, "Body", Vector3.new(2.6, 2.6, 2.6), Vector3.new(0, 0, 0), def.Color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "WingLeft", Vector3.new(1.6, 0.15, 1), Vector3.new(-1.7, 0, 0), Color3.fromRGB(220, 170, 100), Enum.Material.SmoothPlastic, nil, CFrame.Angles(0, 0, math.rad(25)))
	addPart(model, "WingRight", Vector3.new(1.6, 0.15, 1), Vector3.new(1.7, 0, 0), Color3.fromRGB(220, 170, 100), Enum.Material.SmoothPlastic, nil, CFrame.Angles(0, 0, math.rad(-25)))
	addPart(model, "Beak", Vector3.new(0.7, 0.6, 0.9), Vector3.new(0, 0.1, 1.4), Color3.fromRGB(255, 140, 40), Enum.Material.SmoothPlastic, Enum.PartType.Wedge, CFrame.Angles(math.rad(90), 0, 0))
	for i, z in ipairs({ -0.3, 0, 0.3 }) do
		addPart(model, "Comb" .. i, Vector3.new(0.35, 0.35, 0.35), Vector3.new(0, 1.45, z), Color3.fromRGB(220, 40, 40), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
	addPart(model, "FootLeft", Vector3.new(0.5, 0.5, 0.9), Vector3.new(-0.5, -1.5, 0.2), Color3.fromRGB(255, 140, 40))
	addPart(model, "FootRight", Vector3.new(0.5, 0.5, 0.9), Vector3.new(0.5, -1.5, 0.2), Color3.fromRGB(255, 140, 40))
	addEyes(model, 0.5, 1.1, 0.55, 0.5)
end

builders.durian = function(model, def)
	addPart(model, "Body", Vector3.new(3, 3, 3), Vector3.new(0, 0, 0), def.Color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local spikeSpots = {
		Vector3.new(0, 1.6, 0),
		Vector3.new(0, -1.6, 0),
		Vector3.new(-1.6, 0, 0),
		Vector3.new(1.6, 0, 0),
		Vector3.new(0, 0, 1.6),
		Vector3.new(0, 0, -1.6),
		Vector3.new(-1.1, 1.1, 0),
		Vector3.new(1.1, 1.1, 0),
	}
	for i, spot in ipairs(spikeSpots) do
		addPart(model, "Spike" .. i, Vector3.new(0.5, 0.5, 0.5), spot, Color3.fromRGB(60, 140, 50), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
	addCylinderUp(model, "Fuse", 0.12, 0.8, Vector3.new(0, 1.9, 0), Color3.fromRGB(120, 80, 40))
	addPart(model, "Spark", Vector3.new(0.45, 0.45, 0.45), Vector3.new(0, 2.5, 0), Color3.fromRGB(255, 230, 80), Enum.Material.Neon, Enum.PartType.Ball)
	addEyes(model, 0.3, 1.4, 0.6, 0.55)
end

builders.kopi = function(model, def)
	addCylinderUp(model, "Body", 1.5, 3.2, Vector3.new(0, 0, 0), def.Color)
	addCylinderUp(model, "CoffeeTop", 1.35, 0.15, Vector3.new(0, 1.6, 0), Color3.fromRGB(90, 55, 30))
	addCylinderUp(model, "Saucer", 1.9, 0.25, Vector3.new(0, -1.75, 0), Color3.fromRGB(245, 245, 240))
	addCylinderUp(model, "HandleBar", 0.18, 1.6, Vector3.new(1.65, 0, 0), def.Color)
	addPart(model, "HandleTop", Vector3.new(0.5, 0.3, 0.3), Vector3.new(1.55, 0.7, 0), def.Color)
	addPart(model, "HandleBottom", Vector3.new(0.5, 0.3, 0.3), Vector3.new(1.55, -0.7, 0), def.Color)
	addPart(model, "SteamLow", Vector3.new(0.7, 0.7, 0.7), Vector3.new(-0.4, 2.2, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, Enum.PartType.Ball).Transparency = 0.5
	addPart(model, "SteamHigh", Vector3.new(0.55, 0.55, 0.55), Vector3.new(0.4, 2.7, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, Enum.PartType.Ball).Transparency = 0.5
	addEyes(model, 0.3, 1.4, 0.55, 0.55)
end

builders.gerobak = function(model, def)
	addPart(model, "Body", Vector3.new(3.6, 1.5, 2.2), Vector3.new(0, 0.3, 0), def.Color)
	for _, wx in ipairs({ -1.4, 1.4 }) do
		for _, wz in ipairs({ -0.9, 0.9 }) do
			addPart(model, "Wheel", Vector3.new(0.4, 1.4, 1.4), Vector3.new(wx, -0.7, wz), Color3.fromRGB(50, 45, 45), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		end
	end
	addCylinderUp(model, "UmbrellaPole", 0.12, 2.5, Vector3.new(0, 2.2, 0), Color3.fromRGB(80, 75, 85))
	addCylinderUp(model, "Umbrella", 2.2, 0.2, Vector3.new(0, 3.5, 0), Color3.fromRGB(220, 60, 60))
	addPart(model, "Meatball", Vector3.new(0.8, 0.8, 0.8), Vector3.new(0.8, 1.3, 0.3), Color3.fromRGB(225, 170, 110), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addWings(model, 2.1, 0.5, 1.2, 0.9, 20)
	addEyes(model, 0.5, 1.15, 0.7, 0.5)
end

builders.padang = function(model, def)
	addCylinderUp(model, "Body", 2.1, 0.25, Vector3.new(0, -0.5, 0), Color3.fromRGB(255, 250, 240))
	addCylinderUp(model, "GoldRing", 2.3, 0.15, Vector3.new(0, -0.75, 0), Color3.fromRGB(255, 183, 3), Enum.Material.Neon)
	addPart(model, "Rice", Vector3.new(2.2, 2.2, 2.2), Vector3.new(0, 0.6, 0), Color3.fromRGB(255, 250, 240), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "Rendang1", Vector3.new(0.7, 0.7, 0.7), Vector3.new(-0.7, 1.5, 0.4), Color3.fromRGB(110, 70, 35), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "Rendang2", Vector3.new(0.7, 0.7, 0.7), Vector3.new(0.6, 1.6, -0.3), Color3.fromRGB(110, 70, 35), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "Rendang3", Vector3.new(0.7, 0.7, 0.7), Vector3.new(0.1, 1.8, 0.6), Color3.fromRGB(110, 70, 35), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "Chilli", Vector3.new(0.9, 0.3, 0.3), Vector3.new(0.9, 1.4, 0.5), Color3.fromRGB(220, 40, 40), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.rad(40)))
	for i = 1, 3 do
		local angle = math.rad((i - 1) * 120)
		addPart(model, "Sparkle" .. i, Vector3.new(0.3, 0.3, 0.3), Vector3.new(math.cos(angle) * 2.5, 0.5, math.sin(angle) * 2.5), Color3.fromRGB(255, 183, 3), Enum.Material.Neon, Enum.PartType.Ball)
	end
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 210, 120)
	glow.Range = 12
	glow.Brightness = 2
	glow.Parent = model.Body
	addEyes(model, 0.9, 1, 0.5, 0.5)
end

-- The floating name label: name in the rarity colour, rarity and income
-- beneath it, and a green price line that hides once the brainrot is placed.
local function attachLabel(model, def)
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Adornee = model.PrimaryPart
	tag.Size = UDim2.new(0, 240, 0, 100)
	tag.StudsOffsetWorldSpace = Vector3.new(0, (model:GetAttribute("TopOffset") or 3) + 1, 0)
	tag.AlwaysOnTop = true
	tag.Parent = model.PrimaryPart

	local rarityColor = Config.rarityColor(def.Rarity)
	local nameLine = Instance.new("TextLabel")
	nameLine.Name = "NameLine"
	nameLine.Text = def.Name
	nameLine.Font = Enum.Font.LuckiestGuy
	nameLine.TextSize = 18
	nameLine.TextColor3 = rarityColor
	nameLine.BackgroundTransparency = 1
	nameLine.Size = UDim2.new(1, 0, 0, 26)
	nameLine.Position = UDim2.new(0, 0, 0, 0)
	nameLine.TextStrokeTransparency = 0.3
	nameLine.Parent = tag

	local infoLine = Instance.new("TextLabel")
	infoLine.Name = "InfoLine"
	infoLine.Text = string.upper(def.Rarity) .. "  •  $" .. def.Rate .. "/detik"
	infoLine.Font = Enum.Font.GothamBold
	infoLine.TextSize = 15
	infoLine.TextColor3 = Color3.fromRGB(255, 255, 255)
	infoLine.BackgroundTransparency = 1
	infoLine.Size = UDim2.new(1, 0, 0, 22)
	infoLine.Position = UDim2.new(0, 0, 0, 26)
	infoLine.TextStrokeTransparency = 0.3
	infoLine.Parent = tag

	local priceLine = Instance.new("TextLabel")
	priceLine.Name = "PriceLine"
	priceLine.Text = "BELI $" .. def.Price
	priceLine.Font = Enum.Font.GothamBlack
	priceLine.TextSize = 16
	priceLine.TextColor3 = Color3.fromRGB(120, 255, 140)
	priceLine.BackgroundTransparency = 1
	priceLine.Size = UDim2.new(1, 0, 0, 24)
	priceLine.Position = UDim2.new(0, 0, 0, 48)
	priceLine.TextStrokeTransparency = 0.3
	priceLine.Parent = tag
end

-- The prompt every brainrot carries for its whole life. What it does depends
-- on the model's State attribute when a player triggers it.
local function attachPrompt(model, def)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "BELI $" .. def.Price
	prompt.ObjectText = def.Name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		local state = model:GetAttribute("State")
		if state == "conveyor" then
			Spawner.buy(player, model)
		elseif state == "placed" then
			if handlers.take then
				handlers.take(player, model)
			end
		end
	end)
end

-- Build a character model: shape it, scale it, measure it, ring it, label it.
local function buildModel(def)
	local model = Instance.new("Model")
	model.Name = def.Name

	local builder = builders[def.Key]
	builder(model, def)
	model.PrimaryPart = model:FindFirstChild("Body")

	-- Scale every part and its offset from the origin together, so the shape
	-- grows around the origin instead of drifting away from it.
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local frame = descendant.CFrame
			descendant.Size = descendant.Size * SCALE
			descendant.CFrame = CFrame.new(frame.Position * SCALE) * (frame - frame.Position)
		elseif descendant:IsA("PointLight") then
			descendant.Range = descendant.Range * SCALE
		end
	end

	-- Measure the real bounding box now, before the glow ring goes on.
	local boxFrame, boxSize = model:GetBoundingBox()
	local pivotY = model.PrimaryPart.Position.Y
	local bottomOffset = pivotY - (boxFrame.Position.Y - boxSize.Y / 2)
	local topOffset = (boxFrame.Position.Y + boxSize.Y / 2) - pivotY
	model:SetAttribute("BottomOffset", bottomOffset)
	model:SetAttribute("TopOffset", topOffset)

	-- Glowing pad in the rarity colour, just above the model's lowest point.
	local ringRadius = def.Height * 0.62
	local ring = Instance.new("Part")
	ring.Name = "GlowRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, ringRadius * 2, ringRadius * 2)
	ring.CFrame = CFrame.new(0, boxFrame.Position.Y - boxSize.Y / 2 + 0.2, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = Config.rarityColor(def.Rarity)
	ring.Material = Enum.Material.Neon
	ring.Anchored = true
	ring.CanCollide = false
	ring.Parent = model

	model:SetAttribute("CharKey", def.Key)
	model:SetAttribute("CharName", def.Name)
	model:SetAttribute("Rarity", def.Rarity)
	model:SetAttribute("Price", def.Price)
	model:SetAttribute("Rate", def.Rate)
	model:SetAttribute("Size", def.Height)
	model:SetAttribute("State", "conveyor")
	model:SetAttribute("Owner", "")

	attachLabel(model, def)
	attachPrompt(model, def)
	return model
end

-- Weighted random pick across the nine characters.
local function pickCharacter()
	local total = 0
	for _, character in ipairs(Config.Characters) do
		total = total + character.Weight
	end
	local roll = math.random() * total
	for _, character in ipairs(Config.Characters) do
		roll = roll - character.Weight
		if roll <= 0 then
			return character
		end
	end
	return Config.Characters[1]
end

-- Put a fresh brainrot on the belt at x, resting its measured bottom on the
-- belt top with a small gap, facing along the belt.
local function spawnAt(x)
	local def = pickCharacter()
	local model = buildModel(def)
	local restY = Config.Belt.TopY + 0.2 + (model:GetAttribute("BottomOffset") or 0)
	model:PivotTo(CFrame.new(x, restY, 0) * CFrame.Angles(0, math.rad(90), 0))
	model.Parent = workspace
	local entry = { Model = model, X = x, Phase = math.random() * math.pi * 2, BaseY = restY }
	table.insert(active, entry)
	activeByModel[model] = entry
	return model
end

local function removeFromBelt(model)
	local entry = activeByModel[model]
	if not entry then
		return
	end
	for i, other in ipairs(active) do
		if other == entry then
			table.remove(active, i)
			break
		end
	end
	activeByModel[model] = nil
end

-- Buying: hands not full, money enough, then it leaves the belt and rides
-- above the player's head.
function Spawner.buy(player, model)
	if model:GetAttribute("State") ~= "conveyor" then
		return
	end
	if handlers.canCarry and not handlers.canCarry(player) then
		Notify:FireClient(player, "Tanganmu penuh! Taruh dulu yang kamu bawa.", "bad")
		return
	end
	local price = model:GetAttribute("Price") or 0
	if not MoneyService.spend(player, price) then
		Notify:FireClient(player, "Uangmu tidak cukup! Butuh $" .. price .. ".", "bad")
		return
	end
	removeFromBelt(model)
	model:SetAttribute("State", "carried")
	if handlers.carry then
		handlers.carry(player, model)
	end
	Notify:FireClient(player, "Kamu membeli " .. (model:GetAttribute("CharName") or "?") .. "!", "buy")
end

-- A dropped brainrot (tsunami, player left) goes back to the belt start as a
-- fresh free spawn anyone can buy.
function Spawner.returnToBelt(model)
	if not model or not model.Parent then
		return
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("WeldConstraint") then
			descendant:Destroy()
		end
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.Massless = false
		end
	end
	model:SetAttribute("State", "conveyor")
	model:SetAttribute("Owner", "")
	local price = model:GetAttribute("Price") or 0
	local primary = model.PrimaryPart
	local prompt = primary and primary:FindFirstChild("BuyPrompt")
	if prompt then
		prompt.ActionText = "BELI $" .. price
		prompt.Enabled = true
	end
	local tag = primary and primary:FindFirstChild("NameTag")
	local priceLine = tag and tag:FindFirstChild("PriceLine")
	if priceLine then
		priceLine.Visible = true
	end
	local restY = Config.Belt.TopY + 0.2 + (model:GetAttribute("BottomOffset") or 0)
	model:PivotTo(CFrame.new(Config.Belt.StartX, restY, 0) * CFrame.Angles(0, math.rad(90), 0))
	local entry = { Model = model, X = Config.Belt.StartX, Phase = math.random() * math.pi * 2, BaseY = restY }
	table.insert(active, entry)
	activeByModel[model] = entry
end

function Spawner.init(injected)
	handlers = injected
end

function Spawner.start()
	for _, x in ipairs(Config.Belt.Preseed) do
		spawnAt(x)
	end
	task.spawn(function()
		while true do
			task.wait(Config.Belt.SpawnEvery)
			if #active < Config.Belt.MaxOnBelt then
				spawnAt(Config.Belt.StartX)
			end
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		for i = #active, 1, -1 do
			local entry = active[i]
			local model = entry.Model
			if not model.Parent then
				table.remove(active, i)
				activeByModel[model] = nil
			else
				entry.X = entry.X + Config.Belt.Speed * dt
				entry.Phase = entry.Phase + dt * 6
				if entry.X >= Config.Belt.EndX then
					model:Destroy()
					table.remove(active, i)
					activeByModel[model] = nil
				else
					local bob = math.sin(entry.Phase) * 0.15
					local wobble = math.sin(entry.Phase * 0.7) * 0.08
					model:PivotTo(CFrame.new(entry.X, entry.BaseY + bob, 0) * CFrame.Angles(0, math.rad(90), wobble))
				end
			end
		end
	end)
end

return Spawner
