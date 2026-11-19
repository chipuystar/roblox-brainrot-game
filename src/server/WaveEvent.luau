-- WaveEvent.luau
-- The Gerobak Tsunami: every 90 seconds (75 for the first wave) a warning
-- goes out, then a glowing blue wall with eight runaway carts sweeps the
-- market from west to east over 12 seconds. Players standing on any lapak
-- are safe; anyone caught in the open is knocked flying and drops what they
-- carry, and the dropped brainrots go back to the conveyor.
--
-- Hit detection tests each player's position against the wall directly every
-- heartbeat. A touch event on a wall that moves by setting its position is
-- unreliable, and the wall does not collide, so there is no touch to catch.
-- The fling itself is applied on the CLIENT (see Effects): a velocity the
-- server sets on a client-owned character is overwritten by the client's
-- own physics, so the server only tells the client, and the client flings
-- itself.

local Config = require(script.Parent.Config)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Notify = Remotes:WaitForChild("Notify")
local WaveSignal = Remotes:WaitForChild("WaveSignal")
local Knockback = Remotes:WaitForChild("Knockback")
local WaveTimer = Remotes:WaitForChild("WaveTimer")

local WaveEvent = {}

local baseService = nil
local spawner = nil

function WaveEvent.init(context)
	baseService = context.bases
	spawner = context.spawner
end

-- The wall: a tall semi-transparent blue sheet with eight wooden carts
-- spread along it. The sheet is the model's PrimaryPart, so PivotTo moves
-- the whole wall at once.
local function buildWall()
	local wall = Instance.new("Model")
	wall.Name = "TsunamiWall"
	local sheet = Instance.new("Part")
	sheet.Name = "Sheet"
	sheet.Size = Vector3.new(2, 14, 240)
	sheet.CFrame = CFrame.new(-115, 7, 0)
	sheet.Color = Color3.fromRGB(60, 140, 255)
	sheet.Material = Enum.Material.Neon
	sheet.Transparency = 0.4
	sheet.Anchored = true
	sheet.CanCollide = false
	sheet.Parent = wall
	wall.PrimaryPart = sheet
	for i = 1, 8 do
		local z = -105 + (i - 1) * 30
		local cart = Instance.new("Part")
		cart.Name = "Cart" .. i
		cart.Size = Vector3.new(4, 2, 3)
		cart.CFrame = CFrame.new(-115, 1.5, z)
		cart.Color = Color3.fromRGB(180, 120, 60)
		cart.Material = Enum.Material.Wood
		cart.Anchored = true
		cart.CanCollide = false
		cart.Parent = wall
		for _, wheelZ in ipairs({ z - 1.2, z + 1.2 }) do
			local wheel = Instance.new("Part")
			wheel.Name = "Wheel"
			wheel.Shape = Enum.PartType.Cylinder
			wheel.Size = Vector3.new(0.4, 1.2, 1.2)
			wheel.CFrame = CFrame.new(-115, 0.6, wheelZ)
			wheel.Color = Color3.fromRGB(50, 45, 45)
			wheel.Anchored = true
			wheel.CanCollide = false
			wheel.Parent = wall
		end
	end
	wall.Parent = workspace
	return wall
end

local function runWave()
	WaveSignal:FireAllClients("warn", Config.Wave.WarnSecs)
	Notify:FireAllClients("GEROBAK TSUNAMI DATANG! Lari ke lapakmu!", "info")
	task.wait(Config.Wave.WarnSecs)

	WaveSignal:FireAllClients("wave", Config.Wave.SweepSecs)
	local wall = buildWall()
	local hitThisWave = {}
	local speed = 230 / Config.Wave.SweepSecs
	local x = -115
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		x = x + speed * dt
		wall:PivotTo(CFrame.new(x, 7, 0))
		for _, player in ipairs(Players:GetPlayers()) do
			if not hitThisWave[player] then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root then
					local pos = root.Position
					if math.abs(pos.X - x) < 3 and not baseService.isOnAnyBase(pos) then
						hitThisWave[player] = true
						Knockback:FireClient(player, Vector3.new(120, 90, 0))
						local dropped = baseService.dropCarried(player)
						for _, model in ipairs(dropped) do
							spawner.returnToBelt(model)
						end
						Notify:FireClient(player, "Tsunami menghantammu! Brainrot-mu kembali ke konveyor.", "bad")
					end
				end
			end
		end
		if x >= 115 then
			connection:Disconnect()
		end
	end)
	task.wait(Config.Wave.SweepSecs + 0.5)
	if connection.Connected then
		connection:Disconnect()
	end
	wall:Destroy()
	WaveSignal:FireAllClients("clear", 0)
end

-- The countdown the HUD reads, then the wave, then the next countdown.
function WaveEvent.start()
	task.spawn(function()
		local waitSecs = Config.Wave.FirstAt
		while true do
			for t = waitSecs, 1, -1 do
				WaveTimer.Value = t
				task.wait(1)
			end
			WaveTimer.Value = 0
			runWave()
			waitSecs = Config.Wave.Every
		end
	end)
end

return WaveEvent
