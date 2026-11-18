-- Pasar Brainrot: wiring only.
-- Builds the night market, starts the services, connects the remotes and
-- assigns each joining player a lapak. The game logic lives in the modules.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Config)
local WorldBuilder = require(script.WorldBuilder)
local MoneyService = require(script.MoneyService)
local BaseService = require(script.BaseService)
local BrainrotSpawner = require(script.BrainrotSpawner)
local WaveEvent = require(script.WaveEvent)
local RebirthService = require(script.RebirthService)

-- 1. Build the night market, then hand its lapak to BaseService.
local world = WorldBuilder.buildNightMarket()
BaseService.init(world.bases)

-- 2. Start the services.
MoneyService.startIncomeLoop()
BaseService.startPlacementLoop()
BaseService.startLockDisplayLoop()
BrainrotSpawner.start()
WaveEvent.start()

-- 3. Remotes: lock, rebirth and upgrades come from the client HUD.
local remotes = ReplicatedStorage:WaitForChild("Remotes")
remotes.LockBase.OnServerEvent:Connect(function(player)
	local ok, msg = BaseService.lockPlayerBase(player)
	if ok then
		remotes.Notify:FireClient(player, msg, "good")
	else
		remotes.Notify:FireClient(player, msg, "bad")
	end
end)
remotes.RequestRebirth.OnServerEvent:Connect(function(player)
	local ok, msg = RebirthService.tryRebirth(player)
	if not ok then
		remotes.Notify:FireClient(player, msg, "bad")
	end
end)
remotes.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	local ok, msg = RebirthService.tryBuyUpgrade(player, upgradeId)
	if not ok then
		remotes.Notify:FireClient(player, msg, "bad")
	end
end)

-- 4. Players: money state, a lapak, and walk speed kept after respawn.
local function onPlayerAdded(player)
	MoneyService.setupPlayer(player)
	local baseIndex = BaseService.assignPlayerBase(player)
	if not baseIndex then
		remotes.Notify:FireClient(player, "Pasar penuh! Semua lapak terisi.", "bad")
	end
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local data = MoneyService.getData(player)
		if data and data.speedLevel > 0 then
			humanoid.WalkSpeed = Config.UPGRADES.speed.speeds[data.speedLevel]
		end
	end)
end

local function onPlayerRemoving(player)
	local dropped = BaseService.dropCarried(player)
	for _, model in ipairs(dropped) do
		BrainrotSpawner.returnToConveyor(model)
	end
	BaseService.freePlayerBase(player)
	MoneyService.removePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

print("Pasar Brainrot berjalan: " .. #world.bases .. " lapak, " .. #Config.CHARACTERS .. " karakter.")
