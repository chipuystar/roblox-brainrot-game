-- Pasar Brainrot: lapak (bases), carrying, placement, lock and stealing.
-- Each player owns one lapak with six pedestals. A bought brainrot is welded
-- above the player's head; walking back into the lapak places it on the
-- first free pedestal. Another player's brainrot can be taken (stolen) with
-- the AMBIL prompt unless the lapak is locked.

local BaseService = {}

local Config = require(script.Parent.Config)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local bases = {}
local playerBase = {}
local pedestalModels = {}
local carried = {}

function BaseService.init(builtBases)
	bases = builtBases
	for i in ipairs(bases) do
		pedestalModels[i] = {}
	end
end

function BaseService.getBaseIndex(player)
	return playerBase[player]
end

function BaseService.getCarried(player)
	return carried[player] or {}
end

function BaseService.getCarryCapacity(player)
	return player:GetAttribute("CarryCapacity") or 1
end

-- First free lapak, first come first served. Returns nil when all six are taken.
function BaseService.assignPlayerBase(player)
	for i, base in ipairs(bases) do
		if base.owner == nil then
			base.owner = player
			playerBase[player] = i
			base.signOwner.Text = player.DisplayName
			player:SetAttribute("BaseIndex", i)
			-- A glowing beam just above the flags marks YOUR lapak so you
			-- can find it from across the market: the lapak nearest the
			-- spawn is usually not yours, and standing in the wrong lapak
			-- places nothing.
			local beacon = Instance.new("Part")
			beacon.Name = "MyBaseBeacon"
			beacon.Size = Vector3.new(1.5, 13, 1.5)
			beacon.Position = Vector3.new(base.center.X, 7.5, base.center.Z)
			beacon.Color = base.color
			beacon.Material = Enum.Material.Neon
			beacon.Transparency = 0.5
			beacon.Anchored = true
			beacon.CanCollide = false
			beacon.TopSurface = Enum.SurfaceType.Smooth
			beacon.BottomSurface = Enum.SurfaceType.Smooth
			beacon.Parent = Workspace
			local tag = Instance.new("BillboardGui")
			tag.Name = "MyBaseTag"
			tag.Size = UDim2.fromOffset(200, 50)
			tag.StudsOffset = Vector3.new(0, 8, 0)
			tag.AlwaysOnTop = true
			tag.Parent = beacon
			local tagLabel = Instance.new("TextLabel")
			tagLabel.Size = UDim2.fromScale(1, 1)
			tagLabel.BackgroundTransparency = 1
			tagLabel.Text = "LAPAKMU"
			tagLabel.TextColor3 = base.color
			tagLabel.TextSize = 26
			tagLabel.Font = Enum.Font.LuckiestGuy
			tagLabel.TextStrokeTransparency = 0.1
			tagLabel.Parent = tag
			base.beacon = beacon
			return i
		end
	end
	return nil
end

function BaseService.freePlayerBase(player)
	local baseIndex = playerBase[player]
	if not baseIndex then
		return
	end
	local base = bases[baseIndex]
	for _, model in pairs(pedestalModels[baseIndex]) do
		if model and model.Parent then
			model:Destroy()
		end
	end
	pedestalModels[baseIndex] = {}
	base.owner = nil
	base.lockedUntil = 0
	base.lockAvailableAt = 0
	base.signOwner.Text = "Kosong"
	base.lockLabel.Visible = false
	if base.beacon then
		base.beacon:Destroy()
		base.beacon = nil
	end
	playerBase[player] = nil
end

function BaseService.isBaseLocked(baseIndex)
	local base = bases[baseIndex]
	if not base then
		return false
	end
	return os.time() < base.lockedUntil
end

local function getNotifyRemote()
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")
end

local function notify(player, text, kind)
	getNotifyRemote():FireClient(player, text, kind)
end

-- Locks the player's own lapak for 30 seconds (90 second cooldown).
-- Returns ok, message.
function BaseService.lockPlayerBase(player)
	local baseIndex = playerBase[player]
	if not baseIndex then
		return false, "Kamu belum punya lapak."
	end
	local base = bases[baseIndex]
	local now = os.time()
	if now < base.lockAvailableAt then
		return false, "Kunci masih cooldown (" .. (base.lockAvailableAt - now) .. " detik)."
	end
	base.lockedUntil = now + Config.LOCK_DURATION
	base.lockAvailableAt = now + Config.LOCK_COOLDOWN
	player:SetAttribute("BaseLockedUntil", base.lockedUntil)
	return true, "Lapak terkunci 30 detik!"
end

-- Keeps the TERKUNCI line on each lapak sign in sync with its lock.
function BaseService.startLockDisplayLoop()
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = os.time()
			for _, base in ipairs(bases) do
				if base.lockedUntil > now then
					base.lockLabel.Text = "TERKUNCI " .. (base.lockedUntil - now) .. " dtk"
					base.lockLabel.Visible = true
				else
					base.lockLabel.Visible = false
				end
			end
		end
	end)
end

local function updateCarriedAttribute(player)
	local list = carried[player] or {}
	local names = {}
	for _, model in ipairs(list) do
		table.insert(names, model:GetAttribute("CharName") or "?")
	end
	player:SetAttribute("CarriedNames", table.concat(names, ", "))
end

local function restackCarried(player)
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local list = carried[player] or {}
	-- Stack by real model size so bigger brainrots do not clip into each other.
	local y = 1.2
	for _, model in ipairs(list) do
		if model.Parent then
			-- Stack by the real bbox: the pivot sits BottomOffset above
			-- the model's bottom, and the next model starts TopOffset
			-- above this one's pivot plus a gap.
			y += model:GetAttribute("BottomOffset") or 2.5
			model:PivotTo(head.CFrame * CFrame.new(0, y, 0))
			y += (model:GetAttribute("TopOffset") or 2.5) + 0.6
		end
	end
end

-- Welds a brainrot above the player's head so it follows them home.
function BaseService.carryBrainrot(player, model)
	local character = player.Character
	if not character then
		return false
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return false
	end
	-- The PrimaryPart is the model's pivot: re-set it defensively so a
	-- model that somehow lost it can still be carried and placed.
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChild("Body")
	end
	if not model.PrimaryPart then
		return false
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end
	-- Weld EVERY part to the PrimaryPart: Roblox does not hold a model's
	-- parts together on its own, so without these welds only the
	-- PrimaryPart rides the head weld and every other part falls through
	-- the world and is destroyed — the placed brainrot arrives as a bare
	-- Body (for Es Teh, a faint glass cylinder: effectively invisible).
	local primary = model.PrimaryPart
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= primary then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = primary
			weld.Part1 = part
			weld.Parent = primary
		end
	end
	local prompt = primary:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end
	model:SetAttribute("State", "carried")
	local list = carried[player] or {}
	-- Sit on top of the stack by real model size, with a small gap.
	local y = 1.2
	for _, other in ipairs(list) do
		y += (other:GetAttribute("BottomOffset") or 2.5) + (other:GetAttribute("TopOffset") or 2.5) + 0.6
	end
	y += model:GetAttribute("BottomOffset") or 2.5
	model:PivotTo(head.CFrame * CFrame.new(0, y, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = model.PrimaryPart
	weld.Part1 = head
	weld.Parent = model.PrimaryPart
	table.insert(list, model)
	carried[player] = list
	updateCarriedAttribute(player)
	return true
end

-- Drops everything the player carries and returns the models to the caller
-- (the tsunami hands them back to the conveyor).
function BaseService.dropCarried(player)
	local list = carried[player] or {}
	carried[player] = {}
	updateCarriedAttribute(player)
	for _, model in ipairs(list) do
		if model.Parent then
			for _, descendant in ipairs(model:GetDescendants()) do
				if descendant:IsA("WeldConstraint") then
					descendant:Destroy()
				end
			end
		end
	end
	return list
end

local function findFreePedestal(baseIndex)
	for slot = 1, Config.PEDESTALS_PER_BASE do
		if pedestalModels[baseIndex][slot] == nil then
			return slot
		end
	end
	return nil
end

local function findBaseOfModel(model)
	for baseIndex, slots in pairs(pedestalModels) do
		for _, placed in pairs(slots) do
			if placed == model then
				return baseIndex
			end
		end
	end
	return nil
end

local function setPriceLabelVisible(model, visible)
	local label = model:FindFirstChild("NameLabel")
	if label then
		local priceLine = label:FindFirstChild("PriceLine")
		if priceLine then
			priceLine.Visible = visible
		end
	end
end

local function placeOnPedestal(player, baseIndex, slot, model)
	local base = bases[baseIndex]
	local top = base.pedestals[slot]
	-- Rest the model's measured bbox bottom on the pedestal top: the
	-- pivot sits BottomOffset above the bbox bottom, so placing the
	-- pivot at top + BottomOffset puts the model squarely on its stand
	-- instead of sinking or floating.
	local bottomOffset = model:GetAttribute("BottomOffset") or 2.5
	-- Face the market centre: north lapak face +Z, south lapak face -Z.
	local yaw = 0
	if base.center.Z > 0 then
		yaw = math.rad(180)
	end
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChild("Body")
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("WeldConstraint") then
			descendant:Destroy()
		end
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.Massless = false
		end
	end
	model:PivotTo(CFrame.new(top.X, top.Y + bottomOffset + 0.05, top.Z) * CFrame.Angles(0, yaw, 0))
	model:SetAttribute("State", "placed")
	model:SetAttribute("Owner", tostring(player.UserId))
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.ActionText = "AMBIL"
		prompt.Enabled = true
	end
	setPriceLabelVisible(model, false)
	pedestalModels[baseIndex][slot] = model
end

-- Places every carried brainrot the player still has room for.
function BaseService.placeCarriedBrainrots(player)
	local list = carried[player]
	if not list or #list == 0 then
		return 0
	end
	local baseIndex = playerBase[player]
	if not baseIndex then
		return 0
	end
	local placed = 0
	local remaining = {}
	local placedRate = 0
	for _, model in ipairs(list) do
		local slot = findFreePedestal(baseIndex)
		if slot then
			placeOnPedestal(player, baseIndex, slot, model)
			placed += 1
			placedRate += model:GetAttribute("Rate") or 0
		else
			table.insert(remaining, model)
		end
	end
	carried[player] = remaining
	restackCarried(player)
	updateCarriedAttribute(player)
	if placed > 0 then
		notify(player, "Ditaruh di lapak! +$" .. placedRate .. "/detik", "place")
	elseif #remaining > 0 then
		notify(player, "Lapak penuh! Semua pedestal terisi.", "bad")
	end
	return placed
end

function BaseService.isPositionInBaseZone(baseIndex, position)
	local base = bases[baseIndex]
	if not base then
		return false
	end
	return math.abs(position.X - base.center.X) <= Config.BASE_SIZE.x / 2
		and math.abs(position.Z - base.center.Z) <= Config.BASE_SIZE.z / 2
end

function BaseService.isPlayerInBaseZone(player, baseIndex)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	return BaseService.isPositionInBaseZone(baseIndex, root.Position)
end

function BaseService.isPlayerInAnyBaseZone(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	for i in ipairs(bases) do
		if BaseService.isPositionInBaseZone(i, root.Position) then
			return true
		end
	end
	return false
end

-- Walking into your own lapak with a catch places it automatically.
function BaseService.startPlacementLoop()
	task.spawn(function()
		while true do
			task.wait(0.25)
			for player, list in pairs(carried) do
				if #list > 0 then
					local baseIndex = playerBase[player]
					if baseIndex and BaseService.isPlayerInBaseZone(player, baseIndex) then
						-- One bad model must never kill this loop: a
						-- single error here would silently stop ALL
						-- placements for the rest of the session.
						local ok, err = pcall(BaseService.placeCarriedBrainrots, player)
						if not ok then
							warn("Pasar Brainrot: placement failed for " .. player.Name .. ": " .. tostring(err))
						end
					end
				end
			end
		end
	end)
end

-- The AMBIL prompt on a placed brainrot: the owner picks it back up, anyone
-- else steals it unless the lapak is locked.
function BaseService.tryTakeBrainrot(player, model)
	local baseIndex = findBaseOfModel(model)
	if not baseIndex then
		return false
	end
	local ownerId = model:GetAttribute("Owner") or ""
	local myId = tostring(player.UserId)
	if ownerId ~= myId and BaseService.isBaseLocked(baseIndex) then
		notify(player, "Lapak ini terkunci!", "bad")
		return false
	end
	local list = carried[player] or {}
	if #list >= BaseService.getCarryCapacity(player) then
		notify(player, "Tanganmu penuh! Upgrade kapasitas dulu.", "bad")
		return false
	end
	for slot, placed in pairs(pedestalModels[baseIndex]) do
		if placed == model then
			pedestalModels[baseIndex][slot] = nil
		end
	end
	BaseService.carryBrainrot(player, model)
	if ownerId ~= myId then
		notify(player, "Mencuri " .. (model:GetAttribute("CharName") or "brainrot") .. "! Lari ke lapakmu!", "steal")
		local owner = Players:GetPlayerByUserId(tonumber(ownerId) or 0)
		if owner then
			notify(owner, player.DisplayName .. " mencuri brainrotmu!", "bad")
		end
	end
	return true
end

-- Total $/second of the brainrots placed on the player's lapak.
function BaseService.getPlacedIncome(player)
	local baseIndex = playerBase[player]
	if not baseIndex then
		return 0
	end
	local total = 0
	for _, model in pairs(pedestalModels[baseIndex]) do
		if model and model.Parent then
			total += model:GetAttribute("Rate") or 0
		end
	end
	return total
end

return BaseService
