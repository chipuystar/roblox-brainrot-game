-- WorldBuilder.luau
-- Builds the whole night market out of plain Roblox parts at runtime: the
-- raised conveyor, six coloured lapak, lamps, food stalls, the welcome arch
-- and decorations. The baseplate and spawn pad come from default.project.json;
-- everything else is built here so the place file stays small.
--
-- Returns the six lapak records: each holds its centre, colour, pedestals
-- (with their top positions) and the three lines of its wooden sign, so the
-- lapak service can update owners and locks later.

local Config = require(script.Parent.Config)

local WorldBuilder = {}

local GOLD = Color3.fromRGB(255, 183, 3)
local PINK = Color3.fromRGB(255, 77, 109)
local CYAN = Color3.fromRGB(76, 201, 240)
local STONE_GREY = Color3.fromRGB(115, 115, 125)
local WOOD_BROWN = Color3.fromRGB(150, 100, 55)

-- One helper for every static part: size, position, colour, material, shape,
-- whether it blocks movement. Rotation is a CFrame multiplied after the
-- position, so it spins around the part's own centre.
local function addPart(parent, name, size, position, color, material, shape, collide, rotation)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	if rotation then
		part.CFrame = CFrame.new(position) * rotation
	else
		part.CFrame = CFrame.new(position)
	end
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	part.Anchored = true
	part.CanCollide = collide ~= false
	part.Parent = parent
	return part
end

-- A point light parented to a part, in that part's own colour by default.
local function addLight(parent, color, range, brightness)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = parent
	return light
end

-- One line of a floating billboard sign.
local function addSignLine(gui, text, font, size, color, yOffset, height)
	local line = Instance.new("TextLabel")
	line.Text = text
	line.Font = font
	line.TextSize = size
	line.TextColor3 = color
	line.BackgroundTransparency = 1
	line.Size = UDim2.new(1, 0, 0, height)
	line.Position = UDim2.new(0, 0, 0, yOffset)
	line.TextStrokeTransparency = 0.4
	line.Parent = gui
	return line
end

-- The raised orange conveyor with gold skirts, glowing edge strips, direction
-- chevrons and lamp-topped posts at both ends.
local function buildBelt(world)
	local belt = Instance.new("Folder")
	belt.Name = "Belt"
	belt.Parent = world

	addPart(belt, "Body", Vector3.new(150, 3, 10), Vector3.new(0, 1.5, 0), Color3.fromRGB(230, 120, 30))
	for _, side in ipairs({ -1, 1 }) do
		addPart(belt, "Skirt", Vector3.new(150, 1, 0.3), Vector3.new(0, 1.5, side * 5.1), GOLD, Enum.Material.Neon, nil, false)
		addPart(belt, "Edge", Vector3.new(150, 0.8, 0.6), Vector3.new(0, 3.4, side * 4.9), Color3.fromRGB(255, 220, 80), Enum.Material.Neon, nil, false)
	end
	for x = -60, 60, 20 do
		addPart(belt, "Chevron", Vector3.new(3, 0.15, 5), Vector3.new(x, 3.08, 0), GOLD, Enum.Material.Neon, nil, false)
	end
	for _, endX in ipairs({ -74, 74 }) do
		for _, endZ in ipairs({ -4.5, 4.5 }) do
			addPart(belt, "EndPost", Vector3.new(1, 5, 1), Vector3.new(endX, 5.5, endZ), STONE_GREY, Enum.Material.Slate)
			local lamp = addPart(belt, "EndLamp", Vector3.new(1.6, 1, 1.6), Vector3.new(endX, 8.5, endZ), PINK, Enum.Material.Neon)
			addLight(lamp, PINK, 18, 1.5)
		end
	end
end

-- One lapak: neon outline, concrete platform, glowing trim, corner posts with
-- lit tips, a flag, six pedestals and a wooden sign with a floating billboard.
local function buildBase(world, index, def)
	local folder = Instance.new("Folder")
	folder.Name = "Lapak" .. index
	folder.Parent = world

	local cx, cz = def.X, def.Z
	local color = def.Color
	-- The side away from the belt: north lapak face -Z, south lapak face +Z.
	local outward = cz < 0 and -1 or 1

	addPart(folder, "Outline", Vector3.new(27, 0.8, 21), Vector3.new(cx, 0.4, cz), color, Enum.Material.Neon)
	addPart(folder, "Platform", Vector3.new(26, 1, 20), Vector3.new(cx, 0.5, cz), Color3.fromRGB(215, 210, 205), Enum.Material.Concrete)
	addPart(folder, "TrimNorth", Vector3.new(26, 0.5, 0.6), Vector3.new(cx, 1.25, cz - 9.7), color, Enum.Material.Neon, nil, false)
	addPart(folder, "TrimSouth", Vector3.new(26, 0.5, 0.6), Vector3.new(cx, 1.25, cz + 9.7), color, Enum.Material.Neon, nil, false)
	addPart(folder, "TrimWest", Vector3.new(0.6, 0.5, 18.8), Vector3.new(cx - 12.7, 1.25, cz), color, Enum.Material.Neon, nil, false)
	addPart(folder, "TrimEast", Vector3.new(0.6, 0.5, 18.8), Vector3.new(cx + 12.7, 1.25, cz), color, Enum.Material.Neon, nil, false)

	for _, px in ipairs({ -12.5, 12.5 }) do
		for _, pz in ipairs({ -9.5, 9.5 }) do
			addPart(folder, "CornerPost", Vector3.new(0.8, 9, 0.8), Vector3.new(cx + px, 4.5, cz + pz), Color3.fromRGB(200, 200, 205))
			addPart(folder, "CornerTip", Vector3.new(2, 1, 2), Vector3.new(cx + px, 9.5, cz + pz), color, Enum.Material.Neon)
		end
	end

	local poleX = cx + 14.5
	local poleZ = cz + outward * 11.5
	addPart(folder, "FlagPole", Vector3.new(0.4, 10, 0.4), Vector3.new(poleX, 5, poleZ), Color3.fromRGB(90, 85, 95))
	addPart(folder, "FlagBanner", Vector3.new(3, 2, 0.2), Vector3.new(poleX - 1.7, 9, poleZ), color, Enum.Material.Neon)

	local pedestals = {}
	for _, offset in ipairs(Config.PedestalOffsets) do
		local px, pz = cx + offset.X, cz + offset.Z
		addPart(folder, "Pedestal", Vector3.new(5, 1, 5), Vector3.new(px, 1.5, pz), Color3.fromRGB(200, 195, 190), Enum.Material.Marble)
		addPart(folder, "PedestalTop", Vector3.new(5.3, 0.6, 5.3), Vector3.new(px, 2.3, pz), color, Enum.Material.Neon)
		table.insert(pedestals, { Top = Vector3.new(px, 2.6, pz), Model = nil })
	end

	-- Wooden sign on the outer edge, facing the market.
	local signZ = cz + outward * 11
	addPart(folder, "SignPost", Vector3.new(0.5, 5, 0.5), Vector3.new(cx - 4, 2.5, signZ), WOOD_BROWN, Enum.Material.Wood)
	addPart(folder, "SignPost", Vector3.new(0.5, 5, 0.5), Vector3.new(cx + 4, 2.5, signZ), WOOD_BROWN, Enum.Material.Wood)
	local board = addPart(folder, "SignBoard", Vector3.new(10, 3, 0.4), Vector3.new(cx, 5.5, signZ), Color3.fromRGB(160, 110, 60), Enum.Material.Wood)

	local sign = Instance.new("BillboardGui")
	sign.Adornee = board
	sign.Size = UDim2.new(0, 320, 0, 130)
	sign.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	sign.AlwaysOnTop = true
	sign.Parent = board
	local nameLine = addSignLine(sign, "LAPAK " .. index, Enum.Font.LuckiestGuy, 34, color, 0, 46)
	local ownerLine = addSignLine(sign, "Kosong", Enum.Font.GothamBold, 20, Color3.fromRGB(255, 255, 255), 48, 28)
	local lockLine = addSignLine(sign, "TERKUNCI", Enum.Font.GothamBlack, 22, CYAN, 78, 30)
	lockLine.Visible = false

	return {
		Index = index,
		Center = Vector3.new(cx, 0, cz),
		Color = color,
		Pedestals = pedestals,
		NameLabel = nameLine,
		OwnerLabel = ownerLine,
		LockLabel = lockLine,
		LockedUntil = 0,
		CooldownUntil = 0,
	}
end

-- Five pairs of lamp posts along the belt, their neon heads cycling
-- gold, pink, cyan, gold, pink.
local function buildLamps(world)
	local lamps = Instance.new("Folder")
	lamps.Name = "Lamps"
	lamps.Parent = world
	local headColors = { GOLD, PINK, CYAN, GOLD, PINK }
	for i, x in ipairs({ -60, -30, 0, 30, 60 }) do
		local headColor = headColors[i]
		for _, z in ipairs({ -8, 8 }) do
			addPart(lamps, "LampPole", Vector3.new(0.5, 8, 0.5), Vector3.new(x, 4, z), STONE_GREY, Enum.Material.Slate)
			local head = addPart(lamps, "LampHead", Vector3.new(1.5, 1.5, 1.5), Vector3.new(x, 9.1, z), headColor, Enum.Material.Neon)
			addLight(head, headColor, 18, 1.2)
		end
	end
end

-- Four food stalls at the market corners, each with its own roof colour,
-- a counter with goods and a row of warm glowing orbs.
local function buildStalls(world)
	local stalls = Instance.new("Folder")
	stalls.Name = "Stalls"
	stalls.Parent = world
	local defs = {
		{ X = -85, Z = -42, Roof = Color3.fromRGB(255, 60, 60) },
		{ X = 85, Z = -42, Roof = Color3.fromRGB(0, 200, 180) },
		{ X = -85, Z = 42, Roof = Color3.fromRGB(255, 220, 0) },
		{ X = 85, Z = 42, Roof = Color3.fromRGB(157, 78, 221) },
	}
	local goodsColors = { Color3.fromRGB(120, 220, 110), Color3.fromRGB(255, 140, 40), Color3.fromRGB(255, 120, 180) }
	for i, def in ipairs(defs) do
		local stall = Instance.new("Folder")
		stall.Name = "Stall" .. i
		stall.Parent = stalls
		for _, px in ipairs({ -4, 4 }) do
			for _, pz in ipairs({ -3, 3 }) do
				addPart(stall, "Post", Vector3.new(0.5, 5, 0.5), Vector3.new(def.X + px, 2.5, def.Z + pz), WOOD_BROWN, Enum.Material.Wood)
			end
		end
		addPart(stall, "Roof", Vector3.new(10, 0.5, 8), Vector3.new(def.X, 5.2, def.Z), def.Roof)
		addPart(stall, "Counter", Vector3.new(8, 2.5, 3), Vector3.new(def.X, 1.25, def.Z), WOOD_BROWN, Enum.Material.Wood)
		for j, gx in ipairs({ -2.5, 0, 2.5 }) do
			addPart(stall, "Goods", Vector3.new(1, 1, 1), Vector3.new(def.X + gx, 3, def.Z), goodsColors[j])
		end
		-- Warm orbs along the front roof edge, the edge facing the market.
		local frontZ = def.Z < 0 and def.Z + 4 or def.Z - 4
		for _, ox in ipairs({ -4, -2, 0, 2, 4 }) do
			addPart(stall, "Orb", Vector3.new(0.6, 0.6, 0.6), Vector3.new(def.X + ox, 5.2, frontZ), Color3.fromRGB(255, 200, 100), Enum.Material.Neon, Enum.PartType.Ball, false)
		end
	end
end

-- The welcome arch at the south end: stone pillars, a dark beam, the
-- market's name in gold and a lamp of each accent colour on the beam ends.
local function buildArch(world)
	local arch = Instance.new("Folder")
	arch.Name = "Arch"
	arch.Parent = world
	addPart(arch, "Pillar", Vector3.new(1.5, 9, 1.5), Vector3.new(-7, 4.5, 44), Color3.fromRGB(90, 85, 100), Enum.Material.Slate)
	addPart(arch, "Pillar", Vector3.new(1.5, 9, 1.5), Vector3.new(7, 4.5, 44), Color3.fromRGB(90, 85, 100), Enum.Material.Slate)
	local beam = addPart(arch, "Beam", Vector3.new(16, 1.5, 1.5), Vector3.new(0, 9.5, 44), Color3.fromRGB(45, 35, 65))
	local sign = Instance.new("BillboardGui")
	sign.Adornee = beam
	sign.Size = UDim2.new(0, 460, 0, 100)
	sign.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	sign.AlwaysOnTop = true
	sign.Parent = beam
	addSignLine(sign, "PASAR BRAINROT", Enum.Font.LuckiestGuy, 40, GOLD, 0, 52)
	addSignLine(sign, "BELI • BAWA • KAYA", Enum.Font.GothamBold, 20, Color3.fromRGB(255, 255, 255), 54, 28)
	local pinkLamp = addPart(arch, "Lamp", Vector3.new(1, 1, 1), Vector3.new(-7.5, 10.6, 44), PINK, Enum.Material.Neon)
	addLight(pinkLamp, PINK, 15, 1.2)
	local cyanLamp = addPart(arch, "Lamp", Vector3.new(1, 1, 1), Vector3.new(7.5, 10.6, 44), CYAN, Enum.Material.Neon)
	addLight(cyanLamp, CYAN, 15, 1.2)
end

-- Crates and barrels scattered near the market edges, plus a starfield of
-- small glowing balls high above the market.
local function buildDecor(world)
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = world
	local crates = {
		{ X = -95, Z = -15, Turn = 15 },
		{ X = 95, Z = -20, Turn = 30 },
		{ X = -95, Z = 20, Turn = 45 },
		{ X = 95, Z = 15, Turn = 10 },
		{ X = -40, Z = 55, Turn = 25 },
		{ X = 45, Z = -55, Turn = 40 },
	}
	for _, crate in ipairs(crates) do
		addPart(decor, "Crate", Vector3.new(3, 3, 3), Vector3.new(crate.X, 1.5, crate.Z), Color3.fromRGB(165, 115, 65), Enum.Material.Wood, nil, true, CFrame.Angles(0, math.rad(crate.Turn), 0))
	end
	local barrels = {
		{ X = -90, Z = -10, Color = Color3.fromRGB(140, 140, 150) },
		{ X = 90, Z = 10, Color = Color3.fromRGB(80, 120, 200) },
		{ X = 0, Z = 60, Color = Color3.fromRGB(200, 80, 80) },
	}
	for _, barrel in ipairs(barrels) do
		-- A cylinder's axis runs along X, so a (3, 2, 2) cylinder already
		-- lies on its side.
		addPart(decor, "Barrel", Vector3.new(3, 2, 2), Vector3.new(barrel.X, 1, barrel.Z), barrel.Color, Enum.Material.Metal, Enum.PartType.Cylinder)
	end
	local starColors = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 220, 140), Color3.fromRGB(180, 240, 255) }
	for _ = 1, 48 do
		local size = 0.5 + math.random() * 0.5
		local color = starColors[math.random(1, 3)]
		addPart(
			decor,
			"Star",
			Vector3.new(size, size, size),
			Vector3.new(math.random(-140, 140), math.random(70, 130), math.random(-90, 90)),
			color,
			Enum.Material.Neon,
			Enum.PartType.Ball,
			false
		)
	end
end

-- Build the market and hand back the lapak records.
function WorldBuilder.build()
	local world = Instance.new("Folder")
	world.Name = "PasarBrainrot"
	world.Parent = workspace

	buildBelt(world)
	local bases = {}
	for index, def in ipairs(Config.Bases) do
		table.insert(bases, buildBase(world, index, def))
	end
	buildLamps(world)
	buildStalls(world)
	buildArch(world)
	buildDecor(world)

	return bases
end

return WorldBuilder
