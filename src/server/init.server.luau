-- Pasar Brainrot: wiring. Builds the night market, starts every service, and
-- connects the remotes and the player lifecycle.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Config)
local WorldBuilder = require(script.WorldBuilder)
local BrainrotSpawner = require(script.BrainrotSpawner)
local MoneyService = require(script.MoneyService)
local BaseService = require(script.BaseService)
local ProgressionService = require(script.ProgressionService)
local WaveEvent = require(script.WaveEvent)

local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Build the world first, then hand the lapak records to the lapak service.
local bases = WorldBuilder.build()
BaseService.init(bases, BrainrotSpawner, remotes)
BrainrotSpawner.PromptHandler = function(player, model)
	BaseService.handlePrompt(player, model)
end

MoneyService.startIncomeLoop(function(player)
	return BaseService.placedIncome(player)
end)
BaseService.startLoops()
BrainrotSpawner.start()
WaveEvent.start(remotes, BaseService, BrainrotSpawner)

remotes.LockBase.OnServerEvent:Connect(function(player)
	local ok, message = BaseService.lockBase(player)
	remotes.Notify:FireClient(player, message, ok and "good" or "bad")
end)

remotes.RequestRebirth.OnServerEvent:Connect(function(player)
	local ok, message = ProgressionService.tryRebirth(player)
	remotes.Notify:FireClient(player, message, ok and "rebirth" or "bad")
end)

remotes.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	local ok, message = ProgressionService.buyUpgrade(player, upgradeId)
	remotes.Notify:FireClient(player, message, ok and "good" or "bad")
end)

local function onPlayerAdded(player)
	MoneyService.setupPlayer(player)
	local base = BaseService.assignBase(player)
	if not base then
		remotes.Notify:FireClient(player, "Pasar penuh! Tidak ada lapak kosong.", "bad")
	end
	player.CharacterAdded:Connect(function()
		ProgressionService.restoreWalkSpeed(player)
	end)
	if player.Character then
		ProgressionService.restoreWalkSpeed(player)
	end
end

local function onPlayerRemoving(player)
	local dropped = BaseService.dropAll(player)
	for _, model in ipairs(dropped) do
		BrainrotSpawner.returnToBelt(model)
	end
	BaseService.freeBase(player)
	MoneyService.removePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

print("Pasar Brainrot siap: " .. #bases .. " lapak, " .. #Config.CHARACTERS .. " karakter.")
