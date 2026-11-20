-- ProgressionService: rebirths and upgrades. Rebirths reset cash but keep placed
-- brainrots and upgrades; each level adds a permanent +25% income multiplier.
local Config = require(script.Parent.Config)
local MoneyService = require(script.Parent.MoneyService)

local ProgressionService = {}

function ProgressionService.tryRebirth(player)
	local state = MoneyService.getState(player)
	if not state then
		return false, "Data pemain belum siap."
	end
	if state.Rebirths >= #Config.REBIRTHS then
		return false, "Kamu sudah mencapai rebirth maksimal!"
	end
	local nextLevel = Config.REBIRTHS[state.Rebirths + 1]
	if state.Earned < nextLevel.Need then
		return false, "Butuh total $" .. nextLevel.Need .. " (kamu $" .. state.Earned .. ")."
	end
	state.Rebirths += 1
	state.Cash = Config.REBIRTH_CASH
	player:SetAttribute("RebirthTitle", nextLevel.Title)
	MoneyService.sync(player)
	return true, "REBIRTH! Kamu sekarang " .. nextLevel.Title .. "!"
end

function ProgressionService.buyUpgrade(player, id)
	local def = Config.UPGRADES[id]
	if not def then
		return false, "Upgrade tidak dikenal."
	end
	local state = MoneyService.getState(player)
	if not state then
		return false, "Data pemain belum siap."
	end
	local level = 0
	if id == "speed" then
		level = state.SpeedLevel
	elseif id == "carry" then
		level = state.CarryCap - 1
	elseif id == "income" then
		level = state.IncomeLevel
	end
	if level >= #def.Costs then
		return false, def.Name .. " sudah MAX!"
	end
	local price = def.Costs[level + 1]
	if not MoneyService.spend(player, price) then
		return false, "Uang tidak cukup! Butuh $" .. price .. "."
	end
	if id == "speed" then
		state.SpeedLevel += 1
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = def.Speeds[state.SpeedLevel]
		end
	elseif id == "carry" then
		state.CarryCap = 2
	elseif id == "income" then
		state.IncomeLevel += 1
	end
	MoneyService.sync(player)
	return true, def.Name .. " naik ke level " .. (level + 1) .. "!"
end

-- Walk speed is restored from the saved speed level whenever the character spawns.
function ProgressionService.restoreWalkSpeed(player)
	local state = MoneyService.getState(player)
	if not state then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if state.SpeedLevel > 0 then
		humanoid.WalkSpeed = Config.UPGRADES.speed.Speeds[state.SpeedLevel]
	else
		humanoid.WalkSpeed = Config.DEFAULT_WALK_SPEED
	end
end

return ProgressionService
