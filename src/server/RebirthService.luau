-- Pasar Brainrot: rebirths and upgrades.
-- A rebirth resets cash for a permanent +25% income multiplier and a new
-- title; placed brainrots and upgrades stay. Upgrades buy walk speed, a
-- second pair of hands (carry 2) and more $/second.

local RebirthService = {}

local Config = require(script.Parent.Config)
local MoneyService = require(script.Parent.MoneyService)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

function RebirthService.getNextRebirth(player)
	local data = MoneyService.getData(player)
	if not data then
		return nil
	end
	return Config.REBIRTHS[data.rebirths + 1]
end

local function getNotifyRemote()
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")
end

function RebirthService.tryRebirth(player)
	local data = MoneyService.getData(player)
	if not data then
		return false, "Data pemain belum siap."
	end
	local nextRebirth = RebirthService.getNextRebirth(player)
	if not nextRebirth then
		return false, "Kamu sudah mencapai rebirth maksimal!"
	end
	if data.totalEarned < nextRebirth.totalEarned then
		return false, "Butuh total pendapatan $" .. nextRebirth.totalEarned .. " (kamu: $" .. data.totalEarned .. ")."
	end
	data.rebirths += 1
	data.cash = Config.BASE_CASH_AFTER_REBIRTH
	MoneyService.syncValues(player)
	player:SetAttribute("RebirthTitle", nextRebirth.title)
	getNotifyRemote():FireClient(player, "REBIRTH! Gelar baru: " .. nextRebirth.title .. " (+25% pendapatan selamanya)", "rebirth")
	return true, nextRebirth.title
end

local function getUpgradeLevel(data, upgradeId)
	if upgradeId == "speed" then
		return data.speedLevel
	elseif upgradeId == "carry" then
		return data.carryCapacity - 1
	elseif upgradeId == "income" then
		return data.incomeLevel
	end
	return 0
end

function RebirthService.tryBuyUpgrade(player, upgradeId)
	local def = Config.UPGRADES[upgradeId]
	if not def then
		return false, "Upgrade tidak dikenal."
	end
	local data = MoneyService.getData(player)
	if not data then
		return false, "Data pemain belum siap."
	end
	local level = getUpgradeLevel(data, upgradeId)
	if level >= #def.costs then
		return false, def.name .. " sudah maksimal!"
	end
	local cost = def.costs[level + 1]
	if not MoneyService.spendCash(player, cost) then
		return false, "Uang tidak cukup! Butuh $" .. cost .. "."
	end
	if upgradeId == "speed" then
		data.speedLevel += 1
		player:SetAttribute("SpeedLevel", data.speedLevel)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = def.speeds[data.speedLevel]
		end
	elseif upgradeId == "carry" then
		data.carryCapacity = 2
		player:SetAttribute("CarryCapacity", 2)
	elseif upgradeId == "income" then
		data.incomeLevel += 1
		player:SetAttribute("IncomeLevel", data.incomeLevel)
	end
	MoneyService.syncValues(player)
	getNotifyRemote():FireClient(player, def.name .. " dibeli! (" .. (level + 1) .. "/" .. #def.costs .. ")", "good")
	return true, def.name
end

return RebirthService
