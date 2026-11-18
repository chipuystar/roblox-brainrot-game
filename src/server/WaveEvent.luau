-- Pasar Brainrot: the Gerobak Tsunami.
-- Every ~90 seconds a wall of runaway carts sweeps the market from west to
-- east. Players caught outside a lapak are knocked flying and drop whatever
-- they carry — the dropped brainrot walks the conveyor again as a free
-- spawn. Players standing on any lapak are safe, which is what makes the
-- dash home with your catch matter.

local WaveEvent = {}

local Config = require(script.Parent.Config)
local BaseService = require(script.Parent.BaseService)
local BrainrotSpawner = require(script.Parent.BrainrotSpawner)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local waveTimer = nil
local waveSignal = nil
local notifyEvent = nil
local knockbackEvent = nil

local function buildTsunamiCart()
	local cart = Instance.new("Model")
	cart.Name = "TsunamiCart"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3.2, 1.4, 2)
	body.Color = Color3.fromRGB(200, 70, 50)
	body.Material = Enum.Material.WoodPlanks
	body.Anchored = true
	body.CanCollide = false
	body.Parent = cart
	local wheel = Instance.new("Part")
	wheel.Name = "Wheel"
	wheel.Shape = Enum.PartType.Cylinder
	wheel.Size = Vector3.new(0.4, 1.4, 1.4)
	wheel.Position = Vector3.new(-1, -0.9, 1.1)
	wheel.Color = Color3.fromRGB(40, 35, 45)
	wheel.Anchored = true
	wheel.CanCollide = false
	wheel.CFrame = CFrame.new(-1, -0.9, 1.1) * CFrame.Angles(0, math.rad(90), 0)
	wheel.Parent = cart
	local ball = Instance.new("Part")
	ball.Name = "Ball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(1.1, 1.1, 1.1)
	ball.Position = Vector3.new(0.6, 1.2, 0)
	ball.Color = Color3.fromRGB(150, 100, 60)
	ball.Anchored = true
	ball.CanCollide = false
	ball.Parent = cart
	cart.PrimaryPart = body
	return cart
end

-- Knocks the player flying and drops their catch. Returns false when the
-- player is safe on a lapak.
-- The fling itself is applied on the CLIENT via the Knockback remote: a
-- server-set AssemblyLinearVelocity on a client-owned character is
-- overwritten by the client's own physics, which is why the wave used to
-- only make players hop. The client handler sets the velocity on its own
-- HumanoidRootPart, so the fling lands.
local function hitPlayer(player)
	if BaseService.isPlayerInAnyBaseZone(player) then
		return false
	end
	if knockbackEvent then
		-- Flung east, the way the wave travels, with a big vertical pop.
		knockbackEvent:FireClient(player, Vector3.new(90, 70, math.random(-15, 15)))
	end
	local dropped = BaseService.dropCarried(player)
	for _, model in ipairs(dropped) do
		BrainrotSpawner.returnToConveyor(model)
	end
	if #dropped > 0 then
		notifyEvent:FireClient(player, "Tersapu tsunami! Brainrotmu kembali ke konveyor.", "bad")
	else
		notifyEvent:FireClient(player, "Tersapu Gerobak Tsunami!", "bad")
	end
	return true
end

-- Sweeps the glowing wall and its carts across the market.
local function runWave()
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(2, 14, 240)
	wall.Position = Vector3.new(-115, 7, 0)
	wall.Anchored = true
	wall.CanCollide = false
	wall.Transparency = 0.55
	wall.Color = Color3.fromRGB(0, 170, 255)
	wall.Material = Enum.Material.Neon
	wall.Parent = Workspace
	local wallLight = Instance.new("PointLight")
	wallLight.Color = Color3.fromRGB(0, 170, 255)
	wallLight.Range = 40
	wallLight.Brightness = 2
	wallLight.Parent = wall
	local carts = {}
	for i = 1, 8 do
		local cart = buildTsunamiCart()
		cart:PivotTo(CFrame.new(-115, 1.5, -105 + (i - 1) * 30))
		cart.Parent = Workspace
		table.insert(carts, cart)
	end
	local hitThisWave = {}
	local conn = wall.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or hitThisWave[player] then
			return
		end
		if hitPlayer(player) then
			hitThisWave[player] = true
		end
	end)
	local startX, endX = -115, 115
	local duration = Config.WAVE_DURATION
	local t0 = os.clock()
	while os.clock() - t0 < duration do
		local k = (os.clock() - t0) / duration
		local x = startX + (endX - startX) * k
		wall.Position = Vector3.new(x, 7, 0)
		for i, cart in ipairs(carts) do
			cart:PivotTo(CFrame.new(x, 1.5, -105 + (i - 1) * 30))
		end
		-- Deterministic hit check: Touched on a CanCollide=false wall moved
		-- by Position is unreliable, so test every player's position against
		-- the wall directly each Heartbeat. (The Touched connection above
		-- stays as a backup; hitThisWave guards against double-hits.)
		for _, player in ipairs(Players:GetPlayers()) do
			if not hitThisWave[player] and not BaseService.isPlayerInAnyBaseZone(player) then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.X - x) < 5 and math.abs(root.Position.Z) < 120 then
					if hitPlayer(player) then
						hitThisWave[player] = true
					end
				end
			end
		end
		RunService.Heartbeat:Wait()
	end
	conn:Disconnect()
	wall:Destroy()
	for _, cart in ipairs(carts) do
		cart:Destroy()
	end
end

function WaveEvent.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	waveTimer = remotes:WaitForChild("WaveTimer")
	waveSignal = remotes:WaitForChild("WaveSignal")
	notifyEvent = remotes:WaitForChild("Notify")
	knockbackEvent = remotes:WaitForChild("Knockback")
	task.spawn(function()
		task.wait(3)
		local first = true
		while true do
			local waitTime = first and Config.FIRST_WAVE_AT or Config.WAVE_INTERVAL
			first = false
			for t = waitTime, 1, -1 do
				waveTimer.Value = t
				task.wait(1)
			end
			waveSignal:FireAllClients("warning", Config.WAVE_WARNING)
			notifyEvent:FireAllClients("GEROBAK TSUNAMI DATANG! Lari ke lapakmu!", "bad")
			task.wait(Config.WAVE_WARNING)
			waveSignal:FireAllClients("wave", Config.WAVE_DURATION)
			runWave()
			waveSignal:FireAllClients("clear", 0)
		end
	end)
end

return WaveEvent
