-- init.server.luau
-- Wires Pasar Brainrot together: build the market, hand the lapak to the
-- lapak service, start the income, placement, lock, spawner and wave loops,
-- connect the three remotes, and set players up (and clean up after them)
-- as they join and leave.
--
-- The services are wired by injection, not by requiring each other: the
-- spawner needs the lapak service to carry and take, and the wave needs both
-- of them to drop and return brainrots. Requiring across would be a cycle,
-- so this script requires every module once and passes the cross-references
-- into their init functions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Config)
local WorldBuilder = require(script.WorldBuilder)
local MoneyService = require(script.MoneyService)
local BaseService = require(script.BaseService)
local BrainrotSpawner = require(script.BrainrotSpawner)
local WaveEvent = require(script.WaveEvent)
local RebirthService = require(script.RebirthService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local LockBaseRemote = Remotes:WaitForChild("LockBase")
local RebirthRemote = Remotes:WaitForChild("RequestRebirth")
local UpgradeRemote = Remotes:WaitForChild("BuyUpgrade")
local Notify = Remotes:WaitForChild("Notify")

-- 1. Build the night market, then hand the lapak records to the lapak service.
local bases = WorldBuilder.build()
BaseService.init(bases)

-- 2. Give the spawner and the wave the cross-references they need.
BrainrotSpawner.init({
	canCarry = function(player)
		return BaseService.canCarry(player)
	end,
	carry = function(player, model)
		BaseService.carry(player, model)
	end,
	take = function(player, model)
		BaseService.take(player, model)
	end,
})
WaveEvent.init({ bases = BaseService, spawner = BrainrotSpawner })

-- 3. Start every loop: income, placement and lock display, the belt, the wave.
MoneyService.startIncomeLoop(function(player)
	return BaseService.placedIncome(player)
end)
BaseService.startLoops()
BrainrotSpawner.start()
WaveEvent.start()

-- 4. The three remotes. Each notifies the player when it refuses.
LockBaseRemote.OnServerEvent:Connect(function(player)
	local ok, message = BaseService.lockBase(player)
	Notify:FireClient(player, message, ok and "good" or "bad")
end)

RebirthRemote.OnServerEvent:Connect(function(player)
	local ok, message = RebirthService.tryRebirth(player)
	if not ok then
		Notify:FireClient(player, message, "bad")
	end
end)

UpgradeRemote.OnServerEvent:Connect(function(player, upgradeId)
	local ok, message = RebirthService.buyUpgrade(player, upgradeId)
	if not ok then
		Notify:FireClient(player, message, "bad")
	end
end)

-- 5. Players: money state, a lapak, and the saved walk speed on every spawn.
local function setupPlayer(player)
	MoneyService.setupPlayer(player)
	local base = BaseService.assignBase(player)
	if not base then
		Notify:FireClient(player, "Pasar penuh! Kamu menonton dulu.", "bad")
	end
	player.CharacterAdded:Connect(function()
		RebirthService.applyWalkSpeed(player)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

-- 6. Leaving: what they carry goes back to the belt, their lapak is freed,
-- their money state is dropped.
Players.PlayerRemoving:Connect(function(player)
	local dropped = BaseService.dropCarried(player)
	for _, model in ipairs(dropped) do
		BrainrotSpawner.returnToBelt(model)
	end
	BaseService.freeBase(player)
	MoneyService.removePlayer(player)
end)

print("Pasar Brainrot siap: " .. #bases .. " lapak, " .. #Config.Characters .. " karakter.")
