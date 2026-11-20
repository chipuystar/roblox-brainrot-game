-- MoneyService: per-player cash, lifetime earnings, rebirths and upgrades,
-- mirrored to leaderstats and to player attributes the HUD reads.
local Config = require(script.Parent.Config)

local MoneyService = {}

local states = {} -- [player] = { Cash, Earned, Rebirths, SpeedLevel, CarryCap, IncomeLevel }

function MoneyService.multiplier(state)
	return (1 + Config.REBIRTH_BONUS * state.Rebirths) * (1 + Config.INCOME_BONUS * state.IncomeLevel)
end

function MoneyService.sync(player)
	local state = states[player]
	if not state then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash")
		if cash then
			cash.Value = state.Cash
		end
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if rebirths then
			rebirths.Value = state.Rebirths
		end
	end
	player:SetAttribute("TotalEarned", state.Earned)
	player:SetAttribute("Multiplier", MoneyService.multiplier(state))
	player:SetAttribute("SpeedLevel", state.SpeedLevel)
	player:SetAttribute("CarryCapacity", state.CarryCap)
	player:SetAttribute("IncomeLevel", state.IncomeLevel)
end

function MoneyService.setupPlayer(player)
	local state = {
		Cash = Config.START_CASH,
		Earned = 0,
		Rebirths = 0,
		SpeedLevel = 0,
		CarryCap = 1,
		IncomeLevel = 0,
	}
	states[player] = state
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = state.Cash
	cash.Parent = leaderstats
	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats
	player:SetAttribute("TotalEarned", 0)
	player:SetAttribute("Multiplier", 1)
	player:SetAttribute("SpeedLevel", 0)
	player:SetAttribute("CarryCapacity", 1)
	player:SetAttribute("IncomeLevel", 0)
	player:SetAttribute("CarriedNames", "")
	player:SetAttribute("BaseLockedUntil", 0)
	player:SetAttribute("BaseIndex", 0)
	player:SetAttribute("RebirthTitle", "Pemula Pasar")
	return state
end

function MoneyService.removePlayer(player)
	states[player] = nil
end

function MoneyService.getState(player)
	return states[player]
end

-- Spends nothing and returns false when the player cannot afford it.
function MoneyService.spend(player, amount)
	local state = states[player]
	if not state or state.Cash < amount then
		return false
	end
	state.Cash -= amount
	MoneyService.sync(player)
	return true
end

-- Every second, each player's placed brainrots pay their rates times the
-- player's multiplier; the Income leaderstat shows the dollars of that tick.
function MoneyService.startIncomeLoop(placedIncomeFn)
	task.spawn(function()
		while true do
			task.wait(1)
			for player, state in pairs(states) do
				local rate = placedIncomeFn(player)
				local gain = math.floor(rate * MoneyService.multiplier(state) + 0.5)
				if gain > 0 then
					state.Cash += gain
					state.Earned += gain
				end
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local income = leaderstats:FindFirstChild("Income")
					if income then
						income.Value = gain
					end
				end
				MoneyService.sync(player)
			end
		end
	end)
end

return MoneyService
