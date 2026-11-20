-- WaveEvent: the Gerobak Tsunami. A countdown runs on the shared WaveTimer,
-- a warning goes out, then a glowing wall with eight runaway carts sweeps the
-- market and knocks down anyone caught outside a lapak. Players standing on any
-- lapak are safe. Hit detection tests each player's position against the wall
-- every heartbeat: a touch event on a fast-moving non-colliding wall is unreliable.
local Config = require(script.Parent.Config)

local WaveEvent = {}

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local WALL_START_X = -115
local WALL_END_X = 115
local WALL_HEIGHT = 14
local WALL_DEPTH = 240
local KNOCKBACK = Vector3.new(70, 80, 0)

-- The wall and its carts, each part recorded with its offset from the wall's x
-- so the whole set can be slid across the market.
local function buildWallParts()
	local folder = Instance.new("Folder")
	folder.Name = "TsunamiWall"
	folder.Parent = Workspace
	local parts = {}
	local function add(props)
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		for name, value in pairs(props) do
			part[name] = value
		end
		part.Parent = folder
		local origin = props.CFrame
		table.insert(parts, {
			part = part,
			ox = origin.Position.X,
			y = origin.Position.Y,
			z = origin.Position.Z,
			rot = origin - origin.Position,
		})
		return part
	end
	add({
		Name = "WaveWall",
		Size = Vector3.new(2, WALL_HEIGHT, WALL_DEPTH),
		CFrame = CFrame.new(0, WALL_HEIGHT / 2, 0),
		Color = Color3.fromRGB(80, 160, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.4,
	})
	for i = 1, 8 do
		local z = -105 + (i - 1) * 30
		add({
			Name = "WaveCart",
			Size = Vector3.new(3, 1.5, 2),
			CFrame = CFrame.new(0, 1.5, z),
			Color = Color3.fromRGB(170, 120, 70),
			Material = Enum.Material.Wood,
		})
		for _, wx in ipairs({ -1.1, 1.1 }) do
			for _, wz in ipairs({ -0.8, 0.8 }) do
				add({
					Name = "WaveCartWheel",
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new(0.4, 1, 1),
					CFrame = CFrame.new(wx, 0.5, z + wz) * CFrame.Angles(0, math.rad(90), 0),
					Color = Color3.fromRGB(50, 50, 55),
					Material = Enum.Material.SmoothPlastic,
				})
			end
		end
	end
	return folder, parts
end

local function moveParts(parts, x)
	for _, entry in ipairs(parts) do
		entry.part.CFrame = CFrame.new(x + entry.ox, entry.y, entry.z) * entry.rot
	end
end

local function sweep(remotes, baseService, spawner)
	remotes.WaveSignal:FireAllClients("wave", Config.WAVE.SweepTime)
	local folder, parts = buildWallParts()
	local hit = {}
	local startClock = os.clock()
	local done = false
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local t = (os.clock() - startClock) / Config.WAVE.SweepTime
		if t >= 1 then
			done = true
			connection:Disconnect()
			return
		end
		local x = WALL_START_X + (WALL_END_X - WALL_START_X) * t
		moveParts(parts, x)
		for _, player in ipairs(Players:GetPlayers()) do
			if not hit[player] then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.X - x) < 4 and not baseService.isInAnyBase(root.Position) then
					hit[player] = true
					-- The fling is applied on the client: a server-set velocity on a
					-- client-owned character is overwritten by the client's physics.
					remotes.Knockback:FireClient(player, KNOCKBACK)
					local dropped = baseService.dropAll(player)
					for _, model in ipairs(dropped) do
						spawner.returnToBelt(model)
					end
					remotes.Notify:FireClient(player, "Kamu kena Gerobak Tsunami!", "bad")
				end
			end
		end
	end)
	while not done do
		task.wait(0.1)
	end
	folder:Destroy()
	remotes.WaveSignal:FireAllClients("clear", 0)
end

function WaveEvent.start(remotes, baseService, spawner)
	task.spawn(function()
		local timer = remotes.WaveTimer
		local delay = Config.WAVE.FirstDelay
		while true do
			for i = delay, 0, -1 do
				timer.Value = i
				task.wait(1)
			end
			remotes.WaveSignal:FireAllClients("warn", Config.WAVE.WarnTime)
			remotes.Notify:FireAllClients("GEROBAK TSUNAMI DATANG! Lari ke lapakmu!", "info")
			task.wait(Config.WAVE.WarnTime)
			sweep(remotes, baseService, spawner)
			delay = Config.WAVE.Interval
		end
	end)
end

return WaveEvent
