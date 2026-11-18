-- Pasar Brainrot: one place for player money state.
-- Cash, lifetime earnings, rebirths and upgrade levels live in a server
-- table per player and are mirrored to leaderstats values and player
-- attributes so the client HUD can read them. The 1-second income tick pays
-- every placed brainrot its $/second times the player's multiplier.

local MoneyService = {}

local Config = require(script.Parent.Config)
local BaseService = require(script.Parent.BaseService)

local playerData = {}

function MoneyService.getData(player)
	return playerData[player]
end

function MoneyService.getMultiplier(player)
	local data = playerData[player]
	if not data then
		return 1
	end
	local rebirthMult = 1 + Config.REBIRTH_BONUS_PER_LEVEL * data.rebirths
	local incomeMult = 1 + Config.INCOME_BONUS_PER_LEVEL * data.incomeLevel
	return rebirthMult * incomeMult
end

-- Pushes the server table into leaderstats values and player attributes.
function MoneyService.syncValues(player)
	local data = playerData[player]
	if not data then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local cashValue = stats:FindFirstChild("Cash")
		if cashValue then
			cashValue.Value = data.cash
		end
		local rebirthValue = stats:FindFirstChild("Rebirths")
		if rebirthValue then
			rebirthValue.Value = data.rebirths
		end
	end
	player:SetAttribute("TotalEarned", data.totalEarned)
	player:SetAttribute("Multiplier", MoneyService.getMultiplier(player))
	player:SetAttribute("SpeedLevel", data.speedLevel)
	player:SetAttribute("CarryCapacity", data.carryCapacity)
	player:SetAttribute("IncomeLevel", data.incomeLevel)
end

function MoneyService.setupPlayer(player)
	playerData[player] = {
		cash = Config.START_CASH,
		totalEarned = 0,
		rebirths = 0,
		speedLevel = 0,
		carryCapacity = 1,
		incomeLevel = 0,
	}
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = Config.START_CASH
	cash.Parent = stats
	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = stats
	stats.Parent = player
	player:SetAttribute("Multiplier", 1)
	player:SetAttribute("CarryCapacity", 1)
	player:SetAttribute("SpeedLevel", 0)
	player:SetAttribute("IncomeLevel", 0)
	player:SetAttribute("TotalEarned", 0)
	player:SetAttribute("CarriedNames", "")
	player:SetAttribute("BaseLockedUntil", 0)
	player:SetAttribute("BaseIndex", 0)
	player:SetAttribute("RebirthTitle", "Pemula Pasar")
end

function MoneyService.removePlayer(player)
	playerData[player] = nil
end

function MoneyService.addCash(player, amount)
	local data = playerData[player]
	if not data then
		return
	end
	data.cash += amount
	MoneyService.syncValues(player)
end

-- Returns false (and spends nothing) when the player cannot afford it.
function MoneyService.spendCash(player, amount)
	local data = playerData[player]
	if not data or data.cash < amount then
		return false
	end
	data.cash -= amount
	MoneyService.syncValues(player)
	return true
end

-- Every second: each placed brainrot earns its rate times the multiplier.
function MoneyService.startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(1)
			for player, data in pairs(playerData) do
				local baseIncome = BaseService.getPlacedIncome(player)
				local mult = MoneyService.getMultiplier(player)
				local earned = math.floor(baseIncome * mult + 0.5)
				if earned > 0 then
					data.cash += earned
					data.totalEarned += earned
				end
				local stats = player:FindFirstChild("leaderstats")
				if stats then
					local cashValue = stats:FindFirstChild("Cash")
					if cashValue then
						cashValue.Value = data.cash
					end
					local incomeValue = stats:FindFirstChild("Income")
					if incomeValue then
						incomeValue.Value = earned
					end
				end
				player:SetAttribute("TotalEarned", data.totalEarned)
				player:SetAttribute("Multiplier", mult)
			end
		end
	end)
end

return MoneyService
