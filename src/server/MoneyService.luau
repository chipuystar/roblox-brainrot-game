-- MoneyService.luau
-- Owns every player's money: cash, lifetime earnings, rebirth count and
-- upgrade levels. The numbers live in a server table and are mirrored to the
-- player's leaderstats (Cash, Income, Rebirths) and attributes, which is
-- what the HUD reads. Nothing else in the game touches cash directly.

local Config = require(script.Parent.Config)

local MoneyService = {}

local states = {} -- [player] = state table

-- The income multiplier from rebirths and the income upgrade.
function MoneyService.multiplier(player)
	local state = states[player]
	if not state then
		return 1
	end
	return (1 + Config.RebirthBonus * state.Rebirths) * (1 + Config.IncomeBonus * state.IncomeLevel)
end

-- Push the state into the player's attributes for the HUD.
local function syncAttributes(player, state)
	player:SetAttribute("TotalEarned", state.TotalEarned)
	player:SetAttribute("Multiplier", MoneyService.multiplier(player))
	player:SetAttribute("SpeedLevel", state.SpeedLevel)
	player:SetAttribute("CarryCapacity", state.CarryCapacity)
	player:SetAttribute("IncomeLevel", state.IncomeLevel)
	player:SetAttribute("RebirthTitle", state.Title)
end

-- Push the state into leaderstats and attributes at once.
function MoneyService.sync(player)
	local state = states[player]
	if not state then
		return
	end
	local board = player:FindFirstChild("leaderstats")
	if board then
		board.Cash.Value = state.Cash
		board.Rebirths.Value = state.Rebirths
	end
	syncAttributes(player, state)
end

function MoneyService.setupPlayer(player)
	local state = {
		Cash = Config.StartCash,
		TotalEarned = 0,
		Rebirths = 0,
		SpeedLevel = 0,
		CarryCapacity = 1,
		IncomeLevel = 0,
		Title = "Pemula Pasar",
	}
	states[player] = state

	local board = Instance.new("Folder")
	board.Name = "leaderstats"
	board.Parent = player
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = state.Cash
	cash.Parent = board
	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = board
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = board

	-- Defaults for the attributes the lapak service owns, so the HUD never
	-- reads a nil before the player gets a base.
	player:SetAttribute("BaseIndex", 0)
	player:SetAttribute("BaseLockedUntil", 0)
	player:SetAttribute("CarriedNames", "")
	syncAttributes(player, state)
end

function MoneyService.removePlayer(player)
	states[player] = nil
end

function MoneyService.get(player)
	return states[player]
end

function MoneyService.canAfford(player, amount)
	local state = states[player]
	return state ~= nil and state.Cash >= amount
end

-- Spend money, or spend nothing and return false when the player is short.
function MoneyService.spend(player, amount)
	local state = states[player]
	if not state or state.Cash < amount then
		return false
	end
	state.Cash = state.Cash - amount
	local board = player:FindFirstChild("leaderstats")
	if board then
		board.Cash.Value = state.Cash
	end
	return true
end

-- Set the cash outright (a rebirth resets it to the rebirth amount).
function MoneyService.setCash(player, amount)
	local state = states[player]
	if not state then
		return
	end
	state.Cash = amount
	local board = player:FindFirstChild("leaderstats")
	if board then
		board.Cash.Value = state.Cash
	end
end

-- The income loop: every second, each player's placed brainrots pay their
-- rates times the player's multiplier, rounded to the nearest dollar. The
-- Income leaderstat shows what this tick paid, so the HUD's $/detik line is
-- always the live number.
function MoneyService.startIncomeLoop(placedRateFn)
	task.spawn(function()
		while true do
			task.wait(1)
			for player, state in pairs(states) do
				local baseRate = placedRateFn(player) or 0
				local paid = math.floor(baseRate * MoneyService.multiplier(player) + 0.5)
				if paid > 0 then
					state.Cash = state.Cash + paid
					state.TotalEarned = state.TotalEarned + paid
				end
				local board = player:FindFirstChild("leaderstats")
				if board then
					board.Cash.Value = state.Cash
					board.Income.Value = paid
				end
				player:SetAttribute("TotalEarned", state.TotalEarned)
				player:SetAttribute("Multiplier", MoneyService.multiplier(player))
			end
		end
	end)
end

return MoneyService
