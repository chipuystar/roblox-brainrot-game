-- BrainrotSpawner: builds the nine snack characters from plain parts, walks them
-- along the conveyor belt, and hands them back to the belt when they are dropped.
-- Every character is built around the origin facing +Z, then scaled up 1.4x; the
-- measured bounding box (never the nominal height) decides how it rests, is
-- carried and is placed.
local Config = require(script.Parent.Config)

local BrainrotSpawner = {}

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local SCALE = 1.4
local RING_THICKNESS = 0.3

-- Set by the wiring script: called when a player triggers a brainrot's prompt.
BrainrotSpawner.PromptHandler = nil

local onBelt = {} -- { model, x, baseY, phase }

local function addPart(model, props)
	local part = Instance.new("Part")
	part.Anchored = true
	for name, value in pairs(props) do
		part[name] = value
	end
	part.Parent = model
	return part
end

local function ball(model, size, color, x, y, z, extra)
	local props = {
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(size, size, size),
		CFrame = CFrame.new(x, y, z),
		Color = color,
		Material = Enum.Material.SmoothPlastic,
	}
	if extra then
		for k, v in pairs(extra) do
			props[k] = v
		end
	end
	return addPart(model, props)
end

-- A cylinder standing upright (a cylinder's axis is X, so it is tipped 90 degrees).
local function vCylinder(model, radius, height, color, x, y, z, material, transparency)
	return addPart(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, radius * 2, radius * 2),
		CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Transparency = transparency or 0,
	})
end

local function addEyes(model, x, y, z, size)
	ball(model, size, Color3.fromRGB(20, 20, 20), -x, y, z)
	ball(model, size, Color3.fromRGB(20, 20, 20), x, y, z)
end

-- The nine builders. Each builds around the origin and returns its Body part.
local builders = {}

builders.bakso = function(model, def)
	local body = ball(model, 2.2, def.Color, 0, 0, 0)
	body.Name = "Body"
	addPart(model, { Size = Vector3.new(0.4, 0.8, 0.4), CFrame = CFrame.new(-0.5, -1.3, 0), Color = Color3.fromRGB(60, 40, 25), Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(0.4, 0.8, 0.4), CFrame = CFrame.new(0.5, -1.3, 0), Color = Color3.fromRGB(60, 40, 25), Material = Enum.Material.SmoothPlastic })
	vCylinder(model, 1.15, 0.28, Color3.fromRGB(220, 40, 40), 0, 0.7, 0)
	addEyes(model, 0.45, 0.3, 0.95, 0.5)
	return body
end

builders.teh = function(model, def)
	local body = vCylinder(model, 0.95, 2.4, Color3.fromRGB(240, 220, 120), 0, 0, 0, Enum.Material.Glass, 0.25)
	body.Name = "Body"
	vCylinder(model, 0.78, 1.8, Color3.fromRGB(230, 140, 40), 0, -0.2, 0)
	addPart(model, { Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(0.3, 0.9, 0.2), Color = Color3.fromRGB(230, 245, 255), Material = Enum.Material.Glass, Transparency = 0.3 })
	addPart(model, { Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(-0.35, 0.85, -0.1), Color = Color3.fromRGB(230, 245, 255), Material = Enum.Material.Glass, Transparency = 0.3 })
	addPart(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.0, 0.16, 0.16),
		CFrame = CFrame.new(0.5, 1.3, 0) * CFrame.Angles(0, 0, math.rad(72)),
		Color = Color3.fromRGB(220, 40, 40),
		Material = Enum.Material.SmoothPlastic,
	})
	addPart(model, { Size = Vector3.new(1.2, 0.1, 0.6), CFrame = CFrame.new(-1.3, 0.3, 0) * CFrame.Angles(0, 0, math.rad(15)), Color = Color3.fromRGB(245, 245, 245), Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(1.2, 0.1, 0.6), CFrame = CFrame.new(1.3, 0.3, 0) * CFrame.Angles(0, 0, math.rad(-15)), Color = Color3.fromRGB(245, 245, 245), Material = Enum.Material.SmoothPlastic })
	addEyes(model, 0.4, 0.3, 0.85, 0.4)
	return body
end

builders.gorengan = function(model, def)
	local body = addPart(model, { Size = Vector3.new(2.4, 1.7, 1.7), CFrame = CFrame.new(0, -0.2, 0), Color = def.Color, Material = Enum.Material.SmoothPlastic })
	body.Name = "Body"
	ball(model, 1.6, Color3.fromRGB(250, 215, 120), 0, 0.8, 0)
	addPart(model, { Size = Vector3.new(0.5, 0.15, 0.15), CFrame = CFrame.new(-0.5, 0.55, 0.85) * CFrame.Angles(0, 0, math.rad(25)), Color = Color3.fromRGB(60, 35, 15), Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(0.5, 0.15, 0.15), CFrame = CFrame.new(0.5, 0.55, 0.85) * CFrame.Angles(0, 0, math.rad(-25)), Color = Color3.fromRGB(60, 35, 15), Material = Enum.Material.SmoothPlastic })
	addEyes(model, 0.5, 0.2, 0.8, 0.45)
	addPart(model, { Size = Vector3.new(0.8, 0.3, 0.3), CFrame = CFrame.new(-1.4, -0.2, 0), Color = def.Color, Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(0.8, 0.3, 0.3), CFrame = CFrame.new(1.4, -0.2, 0), Color = def.Color, Material = Enum.Material.SmoothPlastic })
	return body
end

builders.kucing = function(model, def)
	local body = ball(model, 2.4, def.Color, 0, 0, 0)
	body.Name = "Body"
	addPart(model, { Shape = Enum.PartType.Wedge, Size = Vector3.new(0.7, 0.7, 0.7), CFrame = CFrame.new(-0.7, 1.4, 0), Color = def.Color, Material = Enum.Material.SmoothPlastic })
	addPart(model, { Shape = Enum.PartType.Wedge, Size = Vector3.new(0.7, 0.7, 0.7), CFrame = CFrame.new(0.7, 1.4, 0), Color = def.Color, Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(0.3, 1.2, 0.3), CFrame = CFrame.new(0, 0.8, -1.3) * CFrame.Angles(math.rad(-20), 0, 0), Color = def.Color, Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(0.3, 0.8, 0.3), CFrame = CFrame.new(0, 1.6, -1.5) * CFrame.Angles(math.rad(20), 0, 0), Color = def.Color, Material = Enum.Material.SmoothPlastic })
	ball(model, 0.3, Color3.fromRGB(255, 150, 180), 0, 0.1, 1.2)
	addEyes(model, 0.55, 0.35, 1.05, 0.54)
	return body
end

builders.geprek = function(model, def)
	local body = ball(model, 2.6, def.Color, 0, 0, 0)
	body.Name = "Body"
	addPart(model, { Size = Vector3.new(1.6, 0.15, 0.9), CFrame = CFrame.new(-1.6, 0, 0) * CFrame.Angles(0, 0, math.rad(20)), Color = Color3.fromRGB(220, 180, 130), Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(1.6, 0.15, 0.9), CFrame = CFrame.new(1.6, 0, 0) * CFrame.Angles(0, 0, math.rad(-20)), Color = Color3.fromRGB(220, 180, 130), Material = Enum.Material.SmoothPlastic })
	addPart(model, { Shape = Enum.PartType.Wedge, Size = Vector3.new(0.6, 0.5, 0.9), CFrame = CFrame.new(0, 0.1, 1.4) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(255, 140, 40), Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(0.3, 0.6, 0.8), CFrame = CFrame.new(0, 1.5, 0), Color = Color3.fromRGB(220, 40, 40), Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(0.4, 0.5, 0.7), CFrame = CFrame.new(-0.5, -1.4, 0.3), Color = Color3.fromRGB(255, 140, 40), Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(0.4, 0.5, 0.7), CFrame = CFrame.new(0.5, -1.4, 0.3), Color = Color3.fromRGB(255, 140, 40), Material = Enum.Material.SmoothPlastic })
	addEyes(model, 0.55, 0.5, 1.1, 0.45)
	return body
end

builders.durian = function(model, def)
	local body = ball(model, 3.0, def.Color, 0, 0, 0)
	body.Name = "Body"
	local spike = Color3.fromRGB(60, 140, 40)
	local spots = {
		{ 0, 1.5, 0 },
		{ 0, -1.5, 0 },
		{ -1.5, 0, 0 },
		{ 1.5, 0, 0 },
		{ 0, 0, 1.5 },
		{ 0, 0, -1.5 },
		{ 1.05, 1.05, 0 },
		{ -1.05, -1.05, 0 },
	}
	for _, s in ipairs(spots) do
		ball(model, 0.5, spike, s[1], s[2], s[3])
	end
	vCylinder(model, 0.12, 0.8, Color3.fromRGB(120, 80, 40), 0, 1.8, 0)
	ball(model, 0.4, Color3.fromRGB(255, 230, 80), 0, 2.3, 0, { Material = Enum.Material.Neon })
	addEyes(model, 0.6, 0.3, 1.4, 0.5)
	return body
end

builders.kopi = function(model, def)
	local body = vCylinder(model, 1.5, 3.2, def.Color, 0, 0, 0)
	body.Name = "Body"
	vCylinder(model, 1.35, 0.2, Color3.fromRGB(60, 35, 15), 0, 1.6, 0)
	vCylinder(model, 1.9, 0.25, Color3.fromRGB(245, 245, 245), 0, -1.7, 0)
	vCylinder(model, 0.15, 1.6, def.Color, 1.7, 0, 0)
	addPart(model, { Size = Vector3.new(0.5, 0.2, 0.2), CFrame = CFrame.new(1.55, 0.7, 0), Color = def.Color, Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(0.5, 0.2, 0.2), CFrame = CFrame.new(1.55, -0.7, 0), Color = def.Color, Material = Enum.Material.SmoothPlastic })
	ball(model, 0.6, Color3.fromRGB(255, 255, 255), -0.4, 2.2, 0, { Transparency = 0.5 })
	ball(model, 0.6, Color3.fromRGB(255, 255, 255), 0.4, 2.2, 0, { Transparency = 0.5 })
	addEyes(model, 0.6, 0.3, 1.4, 0.5)
	return body
end

builders.gerobak = function(model, def)
	local body = addPart(model, { Size = Vector3.new(3.6, 1.5, 2.2), CFrame = CFrame.new(0, 0, 0), Color = Color3.fromRGB(170, 120, 70), Material = Enum.Material.Wood })
	body.Name = "Body"
	for _, wx in ipairs({ -1.4, 1.4 }) do
		for _, wz in ipairs({ -0.9, 0.9 }) do
			addPart(model, {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.4, 1.4, 1.4),
				CFrame = CFrame.new(wx, -1.1, wz) * CFrame.Angles(0, math.rad(90), 0),
				Color = Color3.fromRGB(50, 50, 55),
				Material = Enum.Material.SmoothPlastic,
			})
		end
	end
	vCylinder(model, 0.1, 2.5, Color3.fromRGB(140, 100, 60), 0, 1.8, 0)
	vCylinder(model, 2.2, 0.15, Color3.fromRGB(220, 40, 40), 0, 3.1, 0)
	ball(model, 0.8, Color3.fromRGB(225, 170, 110), 0.8, 1.0, 0)
	addPart(model, { Size = Vector3.new(1.4, 0.1, 0.7), CFrame = CFrame.new(-2.2, 0.3, 0) * CFrame.Angles(0, 0, math.rad(15)), Color = Color3.fromRGB(245, 245, 245), Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(1.4, 0.1, 0.7), CFrame = CFrame.new(2.2, 0.3, 0) * CFrame.Angles(0, 0, math.rad(-15)), Color = Color3.fromRGB(245, 245, 245), Material = Enum.Material.SmoothPlastic })
	addEyes(model, 0.7, 0.2, 1.15, 0.45)
	return body
end

builders.padang = function(model, def)
	local body = vCylinder(model, 2.1, 0.25, Color3.fromRGB(255, 255, 255), 0, 0, 0)
	body.Name = "Body"
	vCylinder(model, 2.3, 0.12, Color3.fromRGB(255, 183, 3), 0, -0.2, 0, Enum.Material.Neon)
	ball(model, 2.2, Color3.fromRGB(255, 252, 240), 0, 0.8, 0)
	local chunk = Color3.fromRGB(90, 55, 30)
	addPart(model, { Size = Vector3.new(0.6, 0.5, 0.6), CFrame = CFrame.new(0.7, 1.6, 0.3), Color = chunk, Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(0.6, 0.5, 0.6), CFrame = CFrame.new(-0.6, 1.7, -0.2), Color = chunk, Material = Enum.Material.SmoothPlastic })
	addPart(model, { Size = Vector3.new(0.6, 0.5, 0.6), CFrame = CFrame.new(0, 1.5, -0.7), Color = chunk, Material = Enum.Material.SmoothPlastic })
	addPart(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.0, 0.24, 0.24),
		CFrame = CFrame.new(0.5, 1.9, 0.5) * CFrame.Angles(math.rad(30), 0, math.rad(20)),
		Color = Color3.fromRGB(220, 40, 40),
		Material = Enum.Material.SmoothPlastic,
	})
	for i = 0, 2 do
		local a = math.rad(i * 120)
		ball(model, 0.3, Color3.fromRGB(255, 210, 80), math.cos(a) * 2.5, 0.5, math.sin(a) * 2.5, { Material = Enum.Material.Neon })
	end
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 200, 100)
	glow.Range = 12
	glow.Brightness = 2
	glow.Parent = body
	addEyes(model, 0.5, 1.0, 1.0, 0.4)
	return body
end

-- Scale every part's size and its offset from the origin, keeping rotations.
local function scaleModel(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Size = descendant.Size * SCALE
			local pos = descendant.CFrame.Position * SCALE
			local rot = descendant.CFrame - descendant.CFrame.Position
			descendant.CFrame = CFrame.new(pos) * rot
		elseif descendant:IsA("PointLight") then
			descendant.Range = descendant.Range * SCALE
		end
	end
end

-- Measure the real bounding box, then add the glow ring, the name label and the
-- prompt. Placement and carrying use these measured offsets, never the nominal
-- body height, because legs, wheels and plates stick out below the body.
local function finishModel(model, def)
	model.Parent = Workspace
	local boxCF, boxSize = model:GetBoundingBox()
	local pivotY = model.PrimaryPart.Position.Y
	local bottomY = boxCF.Position.Y - boxSize.Y / 2
	local topY = boxCF.Position.Y + boxSize.Y / 2
	model:SetAttribute("BottomOffset", pivotY - bottomY)
	model:SetAttribute("TopOffset", topY - pivotY)

	local rarity = Config.RARITIES[def.Rarity]
	local ringRadius = def.Height * 0.62
	local ring = Instance.new("Part")
	ring.Name = "GlowRing"
	ring.Anchored = true
	ring.CanCollide = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(RING_THICKNESS, ringRadius * 2, ringRadius * 2)
	ring.CFrame = CFrame.new(model.PrimaryPart.Position.X, bottomY + 0.2, model.PrimaryPart.Position.Z)
		* CFrame.Angles(0, 0, math.rad(90))
	ring.Color = rarity.Color
	ring.Material = Enum.Material.Neon
	ring.Parent = model

	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Adornee = model.PrimaryPart
	tag.Size = UDim2.fromOffset(220, 96)
	tag.StudsOffsetWorldSpace = Vector3.new(0, topY - pivotY + 1.5, 0)
	tag.AlwaysOnTop = true
	tag.LightInfluence = 0
	tag.Parent = model.PrimaryPart

	local function tagLabel(name, text, font, size, color, yPos, height)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.BackgroundTransparency = 1
		label.Text = text
		label.Font = font
		label.TextSize = size
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.6
		label.Size = UDim2.new(1, 0, 0, height)
		label.Position = UDim2.new(0, 0, 0, yPos)
		label.Parent = tag
		return label
	end

	tagLabel("NameLine", def.Name, Enum.Font.LuckiestGuy, 18, rarity.Color, 0, 34)
	tagLabel("SubLine", string.upper(def.Rarity) .. " • $" .. def.Rate .. "/detik", Enum.Font.GothamBold, 15, Color3.fromRGB(245, 240, 255), 34, 28)
	tagLabel("PriceLine", "BELI $" .. def.Price, Enum.Font.GothamBlack, 16, Color3.fromRGB(120, 255, 140), 62, 30)

	-- One prompt for the model's whole life: buy on the belt, take on a lapak.
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "BELI $" .. def.Price
	prompt.ObjectText = def.Name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		local handler = BrainrotSpawner.PromptHandler
		if handler then
			handler(player, model)
		end
	end)
end

local function buildCharacter(def)
	local model = Instance.new("Model")
	model.Name = def.Name
	local body = builders[def.Key](model, def)
	model.PrimaryPart = body
	scaleModel(model)
	model:SetAttribute("CharKey", def.Key)
	model:SetAttribute("CharName", def.Name)
	model:SetAttribute("Rarity", def.Rarity)
	model:SetAttribute("Price", def.Price)
	model:SetAttribute("Rate", def.Rate)
	model:SetAttribute("Size", def.Height)
	model:SetAttribute("State", "conveyor")
	model:SetAttribute("Owner", "")
	finishModel(model, def)
	return model
end

local function pickCharacter()
	local total = 0
	for _, def in ipairs(Config.CHARACTERS) do
		total += def.Weight
	end
	local roll = math.random() * total
	for _, def in ipairs(Config.CHARACTERS) do
		roll -= def.Weight
		if roll <= 0 then
			return def
		end
	end
	return Config.CHARACTERS[1]
end

local function spawnAt(x)
	local def = pickCharacter()
	local model = buildCharacter(def)
	local belt = Config.BELT
	local baseY = belt.TopY + model:GetAttribute("BottomOffset") + 0.2
	model:PivotTo(CFrame.new(x, baseY, belt.Z) * CFrame.Angles(0, math.rad(90), 0))
	table.insert(onBelt, { model = model, x = x, baseY = baseY, phase = math.random() * math.pi * 2 })
	return model
end

local function startWalkLoop()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local i = 1
		while i <= #onBelt do
			local entry = onBelt[i]
			local model = entry.model
			if not model.Parent then
				table.remove(onBelt, i)
			else
				entry.x += Config.BELT.Speed * dt
				if entry.x >= Config.BELT.EndX then
					model:Destroy()
					table.remove(onBelt, i)
				else
					local bob = math.sin(elapsed * 3 + entry.phase) * 0.15
					local wobble = math.sin(elapsed * 2 + entry.phase) * 0.08
					model:PivotTo(CFrame.new(entry.x, entry.baseY + bob, Config.BELT.Z)
						* CFrame.Angles(0, math.rad(90) + wobble, 0))
					i += 1
				end
			end
		end
	end)
end

function BrainrotSpawner.removeFromBelt(model)
	for i, entry in ipairs(onBelt) do
		if entry.model == model then
			table.remove(onBelt, i)
			return
		end
	end
end

-- A dropped brainrot goes back to the belt start as a fresh free spawn.
function BrainrotSpawner.returnToBelt(model)
	if not model.Parent then
		return
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	model:SetAttribute("State", "conveyor")
	model:SetAttribute("Owner", "")
	local prompt = model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.ActionText = "BELI $" .. model:GetAttribute("Price")
		prompt.Enabled = true
	end
	local tag = model.PrimaryPart:FindFirstChild("NameTag")
	if tag then
		local priceLine = tag:FindFirstChild("PriceLine")
		if priceLine then
			priceLine.Visible = true
		end
	end
	local belt = Config.BELT
	local baseY = belt.TopY + model:GetAttribute("BottomOffset") + 0.2
	model:PivotTo(CFrame.new(belt.StartX, baseY, belt.Z) * CFrame.Angles(0, math.rad(90), 0))
	table.insert(onBelt, { model = model, x = belt.StartX, baseY = baseY, phase = math.random() * math.pi * 2 })
end

function BrainrotSpawner.start()
	for _, x in ipairs({ -72, -45, -18, 9 }) do
		spawnAt(x)
	end
	startWalkLoop()
	task.spawn(function()
		while true do
			task.wait(Config.BELT.SpawnInterval)
			if #onBelt < Config.BELT.MaxOnBelt then
				spawnAt(Config.BELT.StartX)
			end
		end
	end)
end

return BrainrotSpawner
