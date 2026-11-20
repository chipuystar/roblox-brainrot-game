-- WorldBuilder: builds the whole Pasar Brainrot night market from plain parts.
-- The market centre is the origin; the conveyor runs along X at z = 0 and the
-- six lapak sit in two rows, north and south of the belt. Every size, position
-- and colour here comes from Config.
local Config = require(script.Parent.Config)

local WorldBuilder = {}

local Workspace = game:GetService("Workspace")

-- One helper for every part: anchored, parented, properties applied in one call.
local function makePart(parent, props)
	local part = Instance.new("Part")
	part.Anchored = true
	for name, value in pairs(props) do
		part[name] = value
	end
	part.Parent = parent
	return part
end

local function cf(x, y, z)
	return CFrame.new(x, y, z)
end

local function addLight(parent, color, range, brightness)
	local lamp = Instance.new("PointLight")
	lamp.Color = color
	lamp.Range = range
	lamp.Brightness = brightness
	lamp.Parent = parent
	return lamp
end

local function makeBillboard(adornee, size, offset)
	local board = Instance.new("BillboardGui")
	board.Adornee = adornee
	board.Size = size
	board.StudsOffsetWorldSpace = offset
	board.AlwaysOnTop = true
	board.LightInfluence = 0
	board.Parent = adornee
	return board
end

local function makeLabel(parent, text, font, size, color, yPos, height)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = font
	label.TextSize = size
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.6
	label.Size = UDim2.new(1, 0, 0, height)
	label.Position = UDim2.new(0, 0, 0, yPos)
	label.Parent = parent
	return label
end

-- The raised orange machine the brainrots walk on; its top sits at y = 3.
local function buildBelt()
	makePart(Workspace, {
		Name = "ConveyorBelt",
		Size = Vector3.new(150, 3, 10),
		CFrame = cf(0, 1.5, 0),
		Color = Color3.fromRGB(230, 120, 30),
		Material = Enum.Material.SmoothPlastic,
	})
	for _, side in ipairs({ -1, 1 }) do
		makePart(Workspace, {
			Name = "BeltSkirt",
			Size = Vector3.new(150, 1, 0.3),
			CFrame = cf(0, 1.5, side * 5.1),
			Color = Color3.fromRGB(255, 183, 3),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		makePart(Workspace, {
			Name = "BeltEdge",
			Size = Vector3.new(150, 0.8, 0.6),
			CFrame = cf(0, 3.4, side * 4.9),
			Color = Color3.fromRGB(255, 220, 90),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
	end
	for _, x in ipairs({ -60, -40, -20, 0, 20, 40, 60 }) do
		makePart(Workspace, {
			Name = "BeltChevron",
			Size = Vector3.new(3, 0.15, 5),
			CFrame = cf(x, 3.08, 0),
			Color = Color3.fromRGB(255, 183, 3),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
	end
	for _, endX in ipairs({ -74, 74 }) do
		for _, side in ipairs({ -1, 1 }) do
			makePart(Workspace, {
				Name = "BeltPost",
				Size = Vector3.new(1, 5, 1),
				CFrame = cf(endX, 5.5, side * 4.5),
				Color = Color3.fromRGB(120, 120, 130),
				Material = Enum.Material.Slate,
			})
			local lampBlock = makePart(Workspace, {
				Name = "BeltLamp",
				Size = Vector3.new(1.6, 1, 1.6),
				CFrame = cf(endX, 8.5, side * 4.5),
				Color = Color3.fromRGB(255, 77, 109),
				Material = Enum.Material.Neon,
			})
			addLight(lampBlock, Color3.fromRGB(255, 77, 109), 18, 1.5)
		end
	end
end

-- One lapak: neon outline, concrete platform, trim, corner posts, flag, six
-- pedestals and a wooden sign with a floating billboard.
local function buildBase(index, def)
	local cx, cz = def.X, def.Z
	local color = def.Color
	local away = cz < 0 and -1 or 1 -- the side away from the belt

	makePart(Workspace, {
		Name = "BaseOutline" .. index,
		Size = Vector3.new(27, 0.8, 21),
		CFrame = cf(cx, 0.4, cz),
		Color = color,
		Material = Enum.Material.Neon,
	})
	makePart(Workspace, {
		Name = "BasePlatform" .. index,
		Size = Vector3.new(26, 1, 20),
		CFrame = cf(cx, 0.5, cz),
		Color = Color3.fromRGB(205, 205, 200),
		Material = Enum.Material.Concrete,
	})
	for _, side in ipairs({ -1, 1 }) do
		makePart(Workspace, {
			Name = "BaseTrim",
			Size = Vector3.new(26, 0.5, 0.6),
			CFrame = cf(cx, 1.25, cz + side * 9.7),
			Color = color,
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		makePart(Workspace, {
			Name = "BaseTrim",
			Size = Vector3.new(0.6, 0.5, 18.8),
			CFrame = cf(cx + side * 12.7, 1.25, cz),
			Color = color,
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
	end
	for _, ox in ipairs({ -12.5, 12.5 }) do
		for _, oz in ipairs({ -9.5, 9.5 }) do
			makePart(Workspace, {
				Name = "BasePost",
				Size = Vector3.new(0.8, 9, 0.8),
				CFrame = cf(cx + ox, 4.5, cz + oz),
				Color = Color3.fromRGB(100, 100, 110),
				Material = Enum.Material.Slate,
			})
			makePart(Workspace, {
				Name = "BasePostTip",
				Size = Vector3.new(2, 1, 2),
				CFrame = cf(cx + ox, 9.5, cz + oz),
				Color = color,
				Material = Enum.Material.Neon,
			})
		end
	end
	local poleX, poleZ = cx + 14.5, cz + away * 11.5
	makePart(Workspace, {
		Name = "BaseFlagPole",
		Size = Vector3.new(0.4, 10, 0.4),
		CFrame = cf(poleX, 5, poleZ),
		Color = Color3.fromRGB(140, 140, 150),
		Material = Enum.Material.Metal,
	})
	makePart(Workspace, {
		Name = "BaseBanner",
		Size = Vector3.new(3, 2, 0.2),
		CFrame = cf(poleX - 1.7, 9, poleZ),
		Color = color,
		Material = Enum.Material.Neon,
	})
	local pedestals = {}
	for _, off in ipairs(Config.PEDESTAL_OFFSETS) do
		local px, pz = cx + off.X, cz + off.Z
		makePart(Workspace, {
			Name = "Pedestal",
			Size = Vector3.new(5, 1, 5),
			CFrame = cf(px, 1.5, pz),
			Color = Color3.fromRGB(180, 180, 175),
			Material = Enum.Material.Marble,
		})
		makePart(Workspace, {
			Name = "PedestalTop",
			Size = Vector3.new(5.3, 0.6, 5.3),
			CFrame = cf(px, 2.3, pz),
			Color = color,
			Material = Enum.Material.Neon,
		})
		table.insert(pedestals, { Top = Vector3.new(px, 2.6, pz), Occupant = nil })
	end
	local signZ = cz + away * 11
	for _, sx in ipairs({ cx - 4, cx + 4 }) do
		makePart(Workspace, {
			Name = "SignPost",
			Size = Vector3.new(0.5, 5, 0.5),
			CFrame = cf(sx, 2.5, signZ),
			Color = Color3.fromRGB(140, 100, 60),
			Material = Enum.Material.Wood,
		})
	end
	local board = makePart(Workspace, {
		Name = "SignBoard" .. index,
		Size = Vector3.new(10, 3, 0.4),
		CFrame = cf(cx, 5.5, signZ),
		Color = Color3.fromRGB(150, 105, 60),
		Material = Enum.Material.Wood,
	})
	local sign = makeBillboard(board, UDim2.fromOffset(240, 110), Vector3.new(0, 0, 0))
	makeLabel(sign, "LAPAK " .. index, Enum.Font.LuckiestGuy, 30, color, 0, 44)
	local ownerLabel = makeLabel(sign, "Kosong", Enum.Font.GothamBold, 18, Color3.fromRGB(245, 240, 255), 46, 28)
	local lockLabel = makeLabel(sign, "TERKUNCI", Enum.Font.GothamBlack, 16, Color3.fromRGB(76, 201, 240), 76, 26)
	lockLabel.Visible = false

	return {
		Index = index,
		Center = Vector3.new(cx, 0, cz),
		Color = color,
		Pedestals = pedestals,
		SignOwner = ownerLabel,
		SignLock = lockLabel,
		Owner = nil,
		LockedUntil = 0,
		LockCooldownUntil = 0,
		Beacon = nil,
	}
end

-- Five pairs of lamp posts along the belt, head colours cycling gold, pink, cyan.
local function buildLamps()
	local headColors = {
		Color3.fromRGB(255, 183, 3),
		Color3.fromRGB(255, 77, 109),
		Color3.fromRGB(76, 201, 240),
		Color3.fromRGB(255, 183, 3),
		Color3.fromRGB(255, 77, 109),
	}
	for i, x in ipairs({ -60, -30, 0, 30, 60 }) do
		for _, side in ipairs({ -1, 1 }) do
			makePart(Workspace, {
				Name = "LampPole",
				Size = Vector3.new(0.5, 8, 0.5),
				CFrame = cf(x, 4, side * 8),
				Color = Color3.fromRGB(110, 110, 120),
				Material = Enum.Material.Slate,
			})
			local head = makePart(Workspace, {
				Name = "LampHead",
				Size = Vector3.new(1.5, 1.5, 1.5),
				CFrame = cf(x, 9.1, side * 8),
				Color = headColors[i],
				Material = Enum.Material.Neon,
			})
			addLight(head, headColors[i], 18, 1.2)
		end
	end
end

-- Four food stalls at the market corners, one bright roof colour each.
local function buildStalls()
	local roofColors = {
		Color3.fromRGB(230, 60, 60),
		Color3.fromRGB(60, 200, 190),
		Color3.fromRGB(255, 210, 60),
		Color3.fromRGB(150, 90, 220),
	}
	local spots = {
		{ X = -85, Z = -42 },
		{ X = 85, Z = -42 },
		{ X = -85, Z = 42 },
		{ X = 85, Z = 42 },
	}
	for i, spot in ipairs(spots) do
		local sx, sz = spot.X, spot.Z
		for _, ox in ipairs({ -4, 4 }) do
			for _, oz in ipairs({ -3, 3 }) do
				makePart(Workspace, {
					Name = "StallPost",
					Size = Vector3.new(0.5, 5, 0.5),
					CFrame = cf(sx + ox, 2.5, sz + oz),
					Color = Color3.fromRGB(140, 100, 60),
					Material = Enum.Material.Wood,
				})
			end
		end
		makePart(Workspace, {
			Name = "StallRoof",
			Size = Vector3.new(10, 0.5, 8),
			CFrame = cf(sx, 5.2, sz),
			Color = roofColors[i],
			Material = Enum.Material.SmoothPlastic,
		})
		makePart(Workspace, {
			Name = "StallCounter",
			Size = Vector3.new(8, 2.5, 3),
			CFrame = cf(sx, 1.25, sz),
			Color = Color3.fromRGB(150, 105, 60),
			Material = Enum.Material.Wood,
		})
		local goods = {
			Color3.fromRGB(255, 120, 120),
			Color3.fromRGB(120, 255, 140),
			Color3.fromRGB(120, 180, 255),
		}
		for j, gc in ipairs(goods) do
			makePart(Workspace, {
				Name = "StallGoods",
				Size = Vector3.new(1, 1, 1),
				CFrame = cf(sx - 2.5 + (j - 1) * 2.5, 3, sz),
				Color = gc,
				Material = Enum.Material.SmoothPlastic,
			})
		end
		local frontZ = sz + (sz < 0 and 4 or -4)
		for k = 1, 5 do
			makePart(Workspace, {
				Name = "StallOrb",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.5, 0.5, 0.5),
				CFrame = cf(sx - 4 + (k - 1) * 2, 5, frontZ),
				Color = Color3.fromRGB(255, 200, 100),
				Material = Enum.Material.Neon,
			})
		end
	end
end

-- The welcome arch at the south edge, with the game's name over the beam.
local function buildArch()
	for _, side in ipairs({ -1, 1 }) do
		makePart(Workspace, {
			Name = "ArchPillar",
			Size = Vector3.new(1.5, 9, 1.5),
			CFrame = cf(side * 7, 4.5, 44),
			Color = Color3.fromRGB(120, 120, 130),
			Material = Enum.Material.Slate,
		})
		local lampColor = side < 0 and Color3.fromRGB(255, 77, 109) or Color3.fromRGB(76, 201, 240)
		local lampBlock = makePart(Workspace, {
			Name = "ArchLamp",
			Size = Vector3.new(1.2, 1.2, 1.2),
			CFrame = cf(side * 7, 10.6, 44),
			Color = lampColor,
			Material = Enum.Material.Neon,
		})
		addLight(lampBlock, lampColor, 15, 1.2)
	end
	local beam = makePart(Workspace, {
		Name = "ArchBeam",
		Size = Vector3.new(16, 1.5, 1.5),
		CFrame = cf(0, 9.5, 44),
		Color = Color3.fromRGB(45, 30, 60),
		Material = Enum.Material.SmoothPlastic,
	})
	local board = makeBillboard(beam, UDim2.fromOffset(420, 90), Vector3.new(0, 0, 0))
	makeLabel(board, "PASAR BRAINROT", Enum.Font.LuckiestGuy, 36, Color3.fromRGB(255, 183, 3), 0, 48)
	makeLabel(board, "BELI • BAWA • KAYA", Enum.Font.GothamBold, 20, Color3.fromRGB(245, 240, 255), 50, 30)
end

-- Crates, barrels and a starfield high above the market.
local function buildDecor()
	local crates = {
		{ -100, -20 },
		{ 100, 20 },
		{ -95, 30 },
		{ 95, -30 },
		{ -60, 55 },
		{ 60, -55 },
	}
	for _, spot in ipairs(crates) do
		makePart(Workspace, {
			Name = "Crate",
			Size = Vector3.new(3, 3, 3),
			CFrame = cf(spot[1], 1.5, spot[2]),
			Color = Color3.fromRGB(160, 115, 70),
			Material = Enum.Material.Wood,
		})
	end
	local barrels = { { -98, -18 }, { 98, 18 }, { 0, -60 } }
	for _, spot in ipairs(barrels) do
		makePart(Workspace, {
			Name = "Barrel",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3, 2, 2),
			CFrame = cf(spot[1], 1, spot[2]),
			Color = Color3.fromRGB(90, 110, 130),
			Material = Enum.Material.Metal,
		})
	end
	local starColors = {
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 220, 130),
		Color3.fromRGB(180, 240, 255),
	}
	for _ = 1, 48 do
		makePart(Workspace, {
			Name = "Star",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.6, 0.6, 0.6),
			CFrame = cf(math.random(-140, 140), math.random(70, 130), math.random(-90, 90)),
			Color = starColors[math.random(1, 3)],
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
	end
end

function WorldBuilder.build()
	buildBelt()
	buildLamps()
	buildStalls()
	buildArch()
	buildDecor()
	local bases = {}
	for i, def in ipairs(Config.BASES) do
		bases[i] = buildBase(i, def)
	end
	return bases
end

return WorldBuilder
