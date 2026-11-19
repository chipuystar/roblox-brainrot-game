-- RebirthService.luau
-- The long ladder: rebirths and upgrades. A rebirth needs a lifetime
-- earnings total; it resets cash to the rebirth amount, grants a title and a
-- permanent +25% income multiplier, and keeps everything placed and every
-- upgrade bought. Upgrades are bought one level at a time with cash.

local Config = require(script.Parent.Config)
local MoneyService = require(script.Parent.MoneyService)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")

local RebirthService = {}

-- Set the character's walk speed from the saved speed level. Called when an
-- upgrade is bought and again whenever the character respawns.
function RebirthService.applyWalkSpeed(player)
	local state = MoneyService.get(player)
	if not state then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if state.SpeedLevel > 0 then
		humanoid.WalkSpeed = Config.Upgrades.speed.Speeds[state.SpeedLevel]
	else
		humanoid.WalkSpeed = Config.DefaultWalkSpeed
	end
end

function RebirthService.tryRebirth(player)
	local state = MoneyService.get(player)
	if not state then
		return false, "Data pemain belum siap."
	end
	local nextLevel = state.Rebirths + 1
	local tier = Config.Rebirths[nextLevel]
	if not tier then
		return false, "Kamu sudah mencapai rebirth maksimal!"
	end
	if state.TotalEarned < tier.Need then
		return false, "Butuh total penghasilan $" .. tier.Need .. " untuk rebirth."
	end
	state.Rebirths = nextLevel
	state.Title = tier.Title
	MoneyService.setCash(player, Config.RebirthCash)
	MoneyService.sync(player)
	Notify:FireClient(player, "REBIRTH! Kamu sekarang " .. tier.Title .. " (x" .. string.format("%.2f", MoneyService.multiplier(player)) .. " penghasilan)!", "rebirth")
	return true, tier.Title
end

function RebirthService.buyUpgrade(player, id)
	local def = Config.Upgrades[id]
	if not def then
		return false, "Upgrade tidak dikenal."
	end
	local state = MoneyService.get(player)
	if not state then
		return false, "Data pemain belum siap."
	end

	-- The level already owned: speed and income count levels, carry is a
	-- single level (capacity 1 -> 2).
	local current = 0
	if id == "speed" then
		current = state.SpeedLevel
	elseif id == "income" then
		current = state.IncomeLevel
	elseif id == "carry" then
		current = state.CarryCapacity - 1
	end

	local cost = def.Costs[current + 1]
	if not cost then
		return false, def.Name .. " sudah MAX!"
	end
	if not MoneyService.spend(player, cost) then
		return false, "Uangmu tidak cukup! Butuh $" .. cost .. "."
	end

	if id == "speed" then
		state.SpeedLevel = current + 1
		RebirthService.applyWalkSpeed(player)
	elseif id == "income" then
		state.IncomeLevel = current + 1
	elseif id == "carry" then
		state.CarryCapacity = 2
	end
	MoneyService.sync(player)
	Notify:FireClient(player, def.Name .. " dibeli! (" .. def.Desc .. ")", "good")
	return true, def.Name
end

return RebirthService
