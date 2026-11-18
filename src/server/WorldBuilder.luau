-- Pasar Brainrot: builds the sunset market in 3D at runtime.
-- The conveyor belt, six player lapak (bases) with pedestals, lamp posts,
-- food stalls, the welcome arch and decorations are all plain Parts, so the
-- place stays light and the whole world is readable from this one module.

local WorldBuilder = {}

local Config = require(script.Parent.Config)
local Workspace = game:GetService("Workspace")

-- Palette: deliberately LIGHT and saturated against the purple baseplate so
-- every surface reads at sunset. (The DARK_* names are historic; the values
-- are light now for contrast.)
local DARK_FLOOR = Color3.fromRGB(195, 185, 215)
local DARK_STONE = Color3.fromRGB(175, 165, 195)
local BELT_ORANGE = Color3.fromRGB(230, 120, 30)
local WOOD = Color3.fromRGB(120, 80, 45)
local WARM_LIGHT = Color3.fromRGB(255, 200, 90)
local NEON_PINK = Color3.fromRGB(255, 80, 160)
local NEON_CYAN = Color3.fromRGB(80, 220, 255)

local function newPart(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addPointLight(parent, color, range, brightness)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = parent
	return light
end

-- A floating text board that always faces the camera.
local function addBillboard(part, title, titleColor, subtitle, sizeY)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromOffset(220, sizeY or 70)
	gui.StudsOffset = Vector3.new(0, 2.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = part
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = titleColor
	titleLabel.TextSize = 26
	titleLabel.Font = Enum.Font.LuckiestGuy
	titleLabel.TextStrokeTransparency = 0.2
	titleLabel.Parent = gui
	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Subtitle"
	subLabel.Position = UDim2.new(0, 0, 0.6, 0)
	subLabel.Size = UDim2.new(1, 0, 0.4, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = subtitle
	subLabel.TextColor3 = Color3.fromRGB(240, 235, 255)
	subLabel.TextSize = 16
	subLabel.Font = Enum.Font.GothamBold
	subLabel.TextStrokeTransparency = 0.2
	subLabel.Parent = gui
	return gui
end

local function buildConveyorBelt(folder)
	-- The belt is a RAISED machine (3 studs tall, top at y=3), not a floor
	-- stripe: the old 1-stud belt read as flat ground from eye level. Muted
	-- orange against the purple baseplate, with gold side skirts and warm
	-- yellow edges. The top here (y=3) must match
	-- Config.CONVEYOR.beltTopY; the spawner reads it for every placement.
	newPart(folder, "Belt", Vector3.new(150, 3, 10), Vector3.new(0, 1.5, 0), BELT_ORANGE, Enum.Material.SmoothPlastic)
	-- Gold side skirts: muted gold strips along both flanks so the belt
	-- reads as a raised machine from the side. Non-colliding trim.
	local skirtNorth = newPart(folder, "SkirtNorth", Vector3.new(150, 1, 0.3), Vector3.new(0, 1.5, -5.1), Color3.fromRGB(180, 140, 40), Enum.Material.SmoothPlastic)
	skirtNorth.CanCollide = false
	local skirtSouth = newPart(folder, "SkirtSouth", Vector3.new(150, 1, 0.3), Vector3.new(0, 1.5, 5.1), Color3.fromRGB(180, 140, 40), Enum.Material.SmoothPlastic)
	skirtSouth.CanCollide = false
	newPart(folder, "EdgeNorth", Vector3.new(150, 0.8, 0.6), Vector3.new(0, 3.4, -4.9), Color3.fromRGB(200, 160, 60), Enum.Material.SmoothPlastic)
	newPart(folder, "EdgeSouth", Vector3.new(150, 0.8, 0.6), Vector3.new(0, 3.4, 4.9), Color3.fromRGB(200, 160, 60), Enum.Material.SmoothPlastic)
	-- Direction chevrons on the belt so players read which way it runs.
	for i = 1, 7 do
		local x = -60 + (i - 1) * 20
		local chevron = newPart(folder, "Chevron" .. i, Vector3.new(3, 0.15, 5), Vector3.new(x, 3.08, 0), Color3.fromRGB(255, 183, 3), Enum.Material.Neon)
		chevron.CanCollide = false
	end
	-- End posts with lamps, standing ON the belt ends (x=±74, past the
	-- brainrot walk range of -72..72) so the belt reads as a finished
	-- machine from far away.
	for _, x in ipairs({ -74, 74 }) do
		newPart(folder, "EndPost" .. x, Vector3.new(1, 5, 1), Vector3.new(x, 5.5, -4.5), DARK_STONE)
		newPart(folder, "EndPost" .. x .. "B", Vector3.new(1, 5, 1), Vector3.new(x, 5.5, 4.5), DARK_STONE)
		local lamp = newPart(folder, "EndLamp" .. x, Vector3.new(1.6, 1, 1.6), Vector3.new(x, 8.5, 0), NEON_PINK, Enum.Material.Neon)
		addPointLight(lamp, NEON_PINK, 18, 1.5)
	end
end

local function buildPlayerBase(folder, index, def)
	local baseFolder = Instance.new("Folder")
	baseFolder.Name = "Base" .. index
	baseFolder.Parent = folder

	local center = Vector3.new(def.x, 0, def.z)
	-- Coloured outline plate under the platform. It sits ON the floor
	-- (centre y 0.4, 0.8 thick) so no part of it sinks below y=0.
	newPart(baseFolder, "Outline", Vector3.new(27, 0.8, 21), Vector3.new(def.x, 0.4, def.z), def.color, Enum.Material.Neon)
	newPart(baseFolder, "Platform", Vector3.new(26, 1, 20), Vector3.new(def.x, 0.5, def.z), DARK_FLOOR, Enum.Material.Concrete)
	-- Coloured perimeter on the platform top so the lapak's boundary is
	-- unmistakable from across the market. The side strips run between the
	-- end strips (18.8 long) so the corners are not doubled up. The strips
	-- are non-colliding trim: players walk straight over the 0.5 lip.
	local trimNorth = newPart(baseFolder, "TrimNorth", Vector3.new(26, 0.5, 0.6), Vector3.new(def.x, 1.25, def.z - 9.7), def.color, Enum.Material.SmoothPlastic)
	trimNorth.CanCollide = false
	local trimSouth = newPart(baseFolder, "TrimSouth", Vector3.new(26, 0.5, 0.6), Vector3.new(def.x, 1.25, def.z + 9.7), def.color, Enum.Material.SmoothPlastic)
	trimSouth.CanCollide = false
	local trimWest = newPart(baseFolder, "TrimWest", Vector3.new(0.6, 0.5, 18.8), Vector3.new(def.x - 12.7, 1.25, def.z), def.color, Enum.Material.SmoothPlastic)
	trimWest.CanCollide = false
	local trimEast = newPart(baseFolder, "TrimEast", Vector3.new(0.6, 0.5, 18.8), Vector3.new(def.x + 12.7, 1.25, def.z), def.color, Enum.Material.SmoothPlastic)
	trimEast.CanCollide = false
	-- Tall corner posts with glowing tips, so each lapak reads as a
	-- structure from a distance. (No roof: the tallest brainrots would
	-- clip through it.)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			newPart(baseFolder, "CornerPost", Vector3.new(0.8, 9, 0.8), Vector3.new(def.x + sx * 12.5, 4.5, def.z + sz * 9.5), DARK_STONE)
			newPart(baseFolder, "CornerTip", Vector3.new(2, 1, 2), Vector3.new(def.x + sx * 12.5, 9.5, def.z + sz * 9.5), def.color, Enum.Material.Neon)
		end
	end
	-- Tall flag pole at the lapak's outer corner so every lapak reads as a
	-- structure from across the market: a 10-stud pole with a large
	-- base-colour banner near the top. It stands just outside the platform
	-- corner (x +14.5, outer z ±11.5) so it never clips the corner posts
	-- or the sign.
	local outerZ = def.z < 0 and -1 or 1
	local flagX = def.x + 14.5
	local flagZ = def.z + outerZ * 11.5
	newPart(baseFolder, "FlagPole", Vector3.new(0.4, 10, 0.4), Vector3.new(flagX, 5, flagZ), DARK_STONE)
	newPart(baseFolder, "FlagBanner", Vector3.new(3, 2, 0.2), Vector3.new(flagX - 1.7, 9, flagZ), def.color, Enum.Material.Neon)
	-- Six pedestals, two rows of three.
	local pedestals = {}
	for i, off in ipairs(Config.PEDESTAL_OFFSETS) do
		local px = def.x + off.x
		local pz = def.z + off.z
		newPart(baseFolder, "Pedestal" .. i, Vector3.new(5, 1, 5), Vector3.new(px, 1.5, pz), DARK_STONE, Enum.Material.Marble)
		newPart(baseFolder, "PedestalTop" .. i, Vector3.new(5.3, 0.6, 5.3), Vector3.new(px, 2.3, pz), def.color, Enum.Material.SmoothPlastic)
		pedestals[i] = Vector3.new(px, 2.6, pz)
	end
	-- Sign on the outer edge, facing the market.
	local signZ = def.z + (def.z < 0 and -11 or 11)
	newPart(baseFolder, "SignPostA", Vector3.new(0.5, 5, 0.5), Vector3.new(def.x - 4, 2.5, signZ), WOOD)
	newPart(baseFolder, "SignPostB", Vector3.new(0.5, 5, 0.5), Vector3.new(def.x + 4, 2.5, signZ), WOOD)
	local board = newPart(baseFolder, "SignBoard", Vector3.new(10, 3, 0.4), Vector3.new(def.x, 5.5, signZ), Color3.fromRGB(150, 105, 60), Enum.Material.WoodPlanks)
	local gui = addBillboard(board, "LAPAK " .. index, def.color, "Kosong", 70)
	-- Lock line, hidden until the base is locked.
	local lockLabel = Instance.new("TextLabel")
	lockLabel.Name = "LockLine"
	lockLabel.Position = UDim2.new(0, 0, 1, 0)
	lockLabel.Size = UDim2.new(1, 0, 0.4, 0)
	lockLabel.BackgroundTransparency = 1
	lockLabel.Text = "TERKUNCI"
	lockLabel.TextColor3 = NEON_CYAN
	lockLabel.TextSize = 15
	lockLabel.Font = Enum.Font.GothamBlack
	lockLabel.Visible = false
	lockLabel.Parent = gui

	return {
		index = index,
		center = center,
		color = def.color,
		pedestals = pedestals,
		signTitle = gui.Title,
		signOwner = gui.Subtitle,
		lockLabel = lockLabel,
		owner = nil,
		lockedUntil = 0,
		lockAvailableAt = 0,
	}
end

local function buildLampPosts(folder)
	local lampColors = { WARM_LIGHT, NEON_PINK, NEON_CYAN, WARM_LIGHT, NEON_PINK }
	for i, x in ipairs({ -60, -30, 0, 30, 60 }) do
		for _, z in ipairs({ -8, 8 }) do
			local color = lampColors[i]
			newPart(folder, "LampPole", Vector3.new(0.5, 8, 0.5), Vector3.new(x, 4, z), DARK_STONE)
			local head = newPart(folder, "LampHead", Vector3.new(1.5, 1.5, 1.5), Vector3.new(x, 9.1, z), color, Enum.Material.Neon)
			addPointLight(head, color, 18, 1.2)
		end
	end
end

local function buildFoodStalls(folder)
	local stallDefs = {
		{ x = -85, z = -42, roof = Color3.fromRGB(220, 60, 60) },
		{ x = 85, z = -42, roof = Color3.fromRGB(60, 180, 180) },
		{ x = -85, z = 42, roof = Color3.fromRGB(240, 200, 60) },
		{ x = 85, z = 42, roof = Color3.fromRGB(160, 80, 220) },
	}
	for i, def in ipairs(stallDefs) do
		local stall = Instance.new("Folder")
		stall.Name = "Stall" .. i
		stall.Parent = folder
		for _, sx in ipairs({ -4, 4 }) do
			for _, sz in ipairs({ -3, 3 }) do
				newPart(stall, "Post", Vector3.new(0.5, 5, 0.5), Vector3.new(def.x + sx, 2.5, def.z + sz), WOOD)
			end
		end
		newPart(stall, "Roof", Vector3.new(10, 0.5, 8), Vector3.new(def.x, 5.2, def.z), def.roof, Enum.Material.SmoothPlastic)
		newPart(stall, "Counter", Vector3.new(8, 2.5, 3), Vector3.new(def.x, 1.25, def.z), WOOD, Enum.Material.WoodPlanks)
		-- Goods on the counter: little colourful boxes.
		local goods = { Color3.fromRGB(150, 100, 60), Color3.fromRGB(240, 190, 60), Color3.fromRGB(90, 160, 60) }
		for j, gc in ipairs(goods) do
			newPart(stall, "Goods" .. j, Vector3.new(1.4, 1.2, 1.4), Vector3.new(def.x - 2.5 + (j - 1) * 2.5, 3.1, def.z), gc)
		end
		-- A string of glowing orbs along the roof edge.
		for j = 1, 5 do
			local orb = newPart(stall, "Orb" .. j, Vector3.new(0.5, 0.5, 0.5), Vector3.new(def.x - 4 + (j - 1) * 2, 4.6, def.z + 4), WARM_LIGHT, Enum.Material.Neon)
			orb.Shape = Enum.PartType.Ball
			orb.CanCollide = false
		end
	end
end

local function buildWelcomeArch(folder)
	newPart(folder, "ArchPillarL", Vector3.new(1.5, 9, 1.5), Vector3.new(-7, 4.5, 44), DARK_STONE, Enum.Material.Concrete)
	newPart(folder, "ArchPillarR", Vector3.new(1.5, 9, 1.5), Vector3.new(7, 4.5, 44), DARK_STONE, Enum.Material.Concrete)
	local beam = newPart(folder, "ArchBeam", Vector3.new(16, 1.5, 1.5), Vector3.new(0, 9.5, 44), Color3.fromRGB(40, 28, 70), Enum.Material.Concrete)
	addBillboard(beam, "PASAR BRAINROT", Color3.fromRGB(255, 183, 3), "BELI  •  BAWA  •  KAYA", 80)
	local lampL = newPart(folder, "ArchLampL", Vector3.new(1.2, 1.2, 1.2), Vector3.new(-7, 9.8, 44), NEON_PINK, Enum.Material.Neon)
	addPointLight(lampL, NEON_PINK, 16, 1.5)
	local lampR = newPart(folder, "ArchLampR", Vector3.new(1.2, 1.2, 1.2), Vector3.new(7, 9.8, 44), NEON_CYAN, Enum.Material.Neon)
	addPointLight(lampR, NEON_CYAN, 16, 1.5)
end

local function buildDecorations(folder)
	-- Crates and barrels scattered around the market edges.
	local crateSpots = {
		{ x = -78, z = -14 }, { x = -75, z = -10 }, { x = 78, z = 14 },
		{ x = 75, z = 10 }, { x = -40, z = 44 }, { x = 40, z = -44 },
	}
	for i, spot in ipairs(crateSpots) do
		newPart(folder, "Crate" .. i, Vector3.new(3, 3, 3), Vector3.new(spot.x, 1.5, spot.z), WOOD, Enum.Material.WoodPlanks)
	end
	local barrelSpots = { { x = -70, z = 16 }, { x = 70, z = -16 }, { x = 20, z = 46 } }
	for i, spot in ipairs(barrelSpots) do
		local barrel = newPart(folder, "Barrel" .. i, Vector3.new(2, 3, 2), Vector3.new(spot.x, 1.5, spot.z), Color3.fromRGB(100, 70, 40), Enum.Material.Metal)
		barrel.Shape = Enum.PartType.Cylinder
		barrel.CFrame = CFrame.new(spot.x, 1.5, spot.z) * CFrame.Angles(0, 0, math.rad(90))
	end
end

-- A starfield high above the market so the sunset sky feels alive: small
-- Neon balls in white, warm gold and pale cyan. Neon parts are the
-- reliable route — a Sky instance's StarCount alone barely shows at
-- ClockTime 18.0.
local function buildStars(folder)
	local starColors = {
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 220, 130),
		Color3.fromRGB(180, 230, 255),
	}
	for i = 1, 48 do
		local size = 0.7 + math.random() * 0.7
		local star = Instance.new("Part")
		star.Name = "Star" .. i
		star.Shape = Enum.PartType.Ball
		star.Size = Vector3.new(size, size, size)
		star.Position = Vector3.new(
			math.random(-140, 140),
			math.random(70, 130),
			math.random(-90, 90)
		)
		star.Color = starColors[math.random(1, #starColors)]
		star.Material = Enum.Material.Neon
		star.Anchored = true
		star.CanCollide = false
		star.TopSurface = Enum.SurfaceType.Smooth
		star.BottomSurface = Enum.SurfaceType.Smooth
		star.Parent = folder
	end
	-- Real stars too, for when the sky darkens.
	local lighting = game:GetService("Lighting")
	if not lighting:FindFirstChildOfClass("Sky") then
		local sky = Instance.new("Sky")
		sky.StarCount = 3000
		sky.Parent = lighting
	end
end

-- Builds the whole sunset market and returns the base records BaseService needs.
function WorldBuilder.buildNightMarket()
	local world = Instance.new("Folder")
	world.Name = "PasarBrainrot"
	world.Parent = Workspace

	local conveyorFolder = Instance.new("Folder")
	conveyorFolder.Name = "Conveyor"
	conveyorFolder.Parent = world
	buildConveyorBelt(conveyorFolder)

	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = world
	local bases = {}
	for i, def in ipairs(Config.BASES) do
		bases[i] = buildPlayerBase(basesFolder, i, def)
	end

	local decorFolder = Instance.new("Folder")
	decorFolder.Name = "Decor"
	decorFolder.Parent = world
	buildLampPosts(decorFolder)
	buildFoodStalls(decorFolder)
	buildWelcomeArch(decorFolder)
	buildDecorations(decorFolder)
	buildStars(decorFolder)

	return { bases = bases, worldFolder = world }
end

return WorldBuilder
