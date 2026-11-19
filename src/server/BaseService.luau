-- BaseService.luau
-- Owns the lapak: who has one, what they carry, what sits on their
-- pedestals, the lock, and stealing. Carrying welds a brainrot above the
-- player's head; walking home with it places it on the first free pedestal.
--
-- Two Roblox facts shape this module. First, a model's parts do not hold
-- together on their own: when a brainrot is carried, EVERY part gets a
-- WeldConstraint to the PrimaryPart, or only the PrimaryPart rides and the
-- rest falls through the world. Second, placement always uses the model's
-- measured BottomOffset, never its nominal height, or small brainrots sink
-- into their pedestals.

local Config = require(script.Parent.Config)
local MoneyService = require(script.Parent.MoneyService)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")

local BaseService = {}

local bases = {}
local playerBase = {} -- [player] = lapak record
local baseOwner = {} -- [lapak record] = player
local carried = {} -- [player] = list of models
local beacons = {} -- [lapak record] = beacon folder

function BaseService.init(baseList)
	bases = baseList
end

local function refreshCarriedNames(player)
	local names = {}
	for _, model in ipairs(carried[player] or {}) do
		table.insert(names, model:GetAttribute("CharName") or "?")
	end
	player:SetAttribute("CarriedNames", table.concat(names, ", "))
end

function BaseService.getBase(player)
	return playerBase[player]
end

function BaseService.canCarry(player)
	local state = MoneyService.get(player)
	local capacity = state and state.CarryCapacity or 1
	return #(carried[player] or {}) < capacity
end

-- First come, first served. The new owner gets a glowing beacon above their
-- lapak with a floating LAPAKMU tag, so they can find home from anywhere.
function BaseService.assignBase(player)
	for _, base in ipairs(bases) do
		if baseOwner[base] == nil then
			baseOwner[base] = player
			playerBase[player] = base
			base.OwnerLabel.Text = player.DisplayName
			player:SetAttribute("BaseIndex", base.Index)

			local folder = Instance.new("Folder")
			folder.Name = "Beacon"
			local beam = Instance.new("Part")
			beam.Name = "Beam"
			beam.Size = Vector3.new(1.5, 13, 1.5)
			beam.CFrame = CFrame.new(base.Center.X, 7.5, base.Center.Z)
			beam.Color = base.Color
			beam.Material = Enum.Material.Neon
			beam.Transparency = 0.5
			beam.Anchored = true
			beam.CanCollide = false
			beam.Parent = folder
			local tag = Instance.new("BillboardGui")
			tag.Adornee = beam
			tag.Size = UDim2.new(0, 200, 0, 50)
			tag.StudsOffsetWorldSpace = Vector3.new(0, 7.5, 0)
			tag.AlwaysOnTop = true
			tag.Parent = beam
			local text = Instance.new("TextLabel")
			text.Text = "LAPAKMU"
			text.Font = Enum.Font.LuckiestGuy
			text.TextSize = 30
			text.TextColor3 = Color3.fromRGB(255, 183, 3)
			text.BackgroundTransparency = 1
			text.Size = UDim2.new(1, 0, 1, 0)
			text.TextStrokeTransparency = 0.4
			text.Parent = tag
			folder.Parent = workspace
			beacons[base] = folder
			return base
		end
	end
	return nil
end

-- Freeing a lapak destroys what stood on it, clears the owner and lock,
-- resets the sign and takes the beacon down.
function BaseService.freeBase(player)
	local base = playerBase[player]
	if not base then
		return
	end
	for _, pedestal in ipairs(base.Pedestals) do
		if pedestal.Model then
			pedestal.Model:Destroy()
			pedestal.Model = nil
		end
	end
	baseOwner[base] = nil
	playerBase[player] = nil
	base.OwnerLabel.Text = "Kosong"
	base.LockLabel.Visible = false
	base.LockedUntil = 0
	base.CooldownUntil = 0
	local beacon = beacons[base]
	if beacon then
		beacon:Destroy()
		beacons[base] = nil
	end
end

-- Weld a brainrot above the player's head. Carried models stack by their real
-- measured heights with a small gap, starting 1.2 studs above the head.
function BaseService.carry(player, model)
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.Massless = true
		end
	end
	local primary = model.PrimaryPart
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant ~= primary then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = primary
			weld.Part1 = descendant
			weld.Parent = primary
		end
	end
	local stackY = head.Position.Y + head.Size.Y / 2 + 1.2
	for _, other in ipairs(carried[player] or {}) do
		stackY = stackY + (other:GetAttribute("BottomOffset") or 0) + (other:GetAttribute("TopOffset") or 0) + 0.3
	end
	local bottom = model:GetAttribute("BottomOffset") or 0
	model:PivotTo(CFrame.new(head.Position.X, stackY + bottom, head.Position.Z))
	local hold = Instance.new("WeldConstraint")
	hold.Part0 = head
	hold.Part1 = primary
	hold.Parent = primary
	local prompt = primary:FindFirstChild("BuyPrompt")
	if prompt then
		prompt.Enabled = false
	end
	local list = carried[player] or {}
	table.insert(list, model)
	carried[player] = list
	refreshCarriedNames(player)
end

-- Set a carried brainrot down on a pedestal: welds off, parts anchored
-- again, bottom resting on the pedestal top, facing the market centre.
-- North lapak face +Z; south lapak turn around to face -Z.
local function placeOnPedestal(player, base, pedestal, model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("WeldConstraint") then
			descendant:Destroy()
		end
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.Massless = false
		end
	end
	local bottom = model:GetAttribute("BottomOffset") or 0
	local facing = base.Center.Z < 0 and 0 or math.rad(180)
	model:PivotTo(CFrame.new(pedestal.Top.X, pedestal.Top.Y + bottom + 0.05, pedestal.Top.Z) * CFrame.Angles(0, facing, 0))
	model:SetAttribute("State", "placed")
	model:SetAttribute("Owner", tostring(player.UserId))
	pedestal.Model = model
	local prompt = model.PrimaryPart:FindFirstChild("BuyPrompt")
	if prompt then
		prompt.ActionText = "AMBIL"
		prompt.Enabled = true
	end
	local tag = model.PrimaryPart:FindFirstChild("NameTag")
	local priceLine = tag and tag:FindFirstChild("PriceLine")
	if priceLine then
		priceLine.Visible = false
	end
	Notify:FireClient(player, "Ditaruh! +" .. (model:GetAttribute("Rate") or 0) .. "$/detik", "place")
end

-- A carrying player standing inside their own lapak zone places what they
-- carry on the first free pedestals. One bad model must never kill the loop,
-- so each placement runs protected.
local function tryPlace(player)
	local base = playerBase[player]
	if not base then
		return
	end
	local list = carried[player]
	if not list or #list == 0 then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local pos = root.Position
	if math.abs(pos.X - base.Center.X) > 13 or math.abs(pos.Z - base.Center.Z) > 10 then
		return
	end
	local remaining = {}
	for _, model in ipairs(list) do
		local pedestal = nil
		for _, candidate in ipairs(base.Pedestals) do
			if candidate.Model == nil then
				pedestal = candidate
				break
			end
		end
		if not pedestal then
			Notify:FireClient(player, "Lapakmu penuh!", "bad")
			table.insert(remaining, model)
		else
			local ok = pcall(placeOnPedestal, player, base, pedestal, model)
			if not ok then
				table.insert(remaining, model)
			end
		end
	end
	carried[player] = remaining
	refreshCarriedNames(player)
end

-- Lock your own lapak for 30 seconds; afterwards the lock rests 90 seconds.
function BaseService.lockBase(player)
	local base = playerBase[player]
	if not base then
		return false, "Kamu belum punya lapak!"
	end
	local now = os.time()
	if base.LockedUntil > now then
		return false, "Lapakmu sudah terkunci!"
	end
	if base.CooldownUntil > now then
		return false, "Kunci masih cooldown (" .. (base.CooldownUntil - now) .. " dtk)."
	end
	base.LockedUntil = now + Config.Lock.Duration
	base.CooldownUntil = now + Config.Lock.Duration + Config.Lock.Cooldown
	player:SetAttribute("BaseLockedUntil", base.LockedUntil)
	return true, "Lapak terkunci selama " .. Config.Lock.Duration .. " detik!"
end

-- Triggering the prompt on a placed brainrot: take your own back, or steal
-- someone else's — unless their lapak is locked, or your hands are full.
function BaseService.take(player, model)
	if model:GetAttribute("State") ~= "placed" then
		return
	end
	local ownerId = model:GetAttribute("Owner") or ""
	local owner = ownerId ~= "" and Players:GetPlayerByUserId(tonumber(ownerId)) or nil
	local homeBase, homePedestal = nil, nil
	for _, base in ipairs(bases) do
		for _, pedestal in ipairs(base.Pedestals) do
			if pedestal.Model == model then
				homeBase, homePedestal = base, pedestal
				break
			end
		end
		if homeBase then
			break
		end
	end
	if homeBase and homeBase.LockedUntil > os.time() and owner ~= player then
		Notify:FireClient(player, "Lapak ini terkunci!", "bad")
		return
	end
	if not BaseService.canCarry(player) then
		Notify:FireClient(player, "Tanganmu penuh!", "bad")
		return
	end
	if homePedestal then
		homePedestal.Model = nil
	end
	model:SetAttribute("State", "carried")
	BaseService.carry(player, model)
	local name = model:GetAttribute("CharName") or "brainrot"
	if owner and owner ~= player then
		Notify:FireClient(player, "Kamu mencuri " .. name .. "!", "steal")
		Notify:FireClient(owner, player.DisplayName .. " mencuri " .. name .. " darimu!", "bad")
	else
		Notify:FireClient(player, "Kamu mengambil " .. name .. ".", "info")
	end
end

-- The dollars per second a player's placed brainrots pay, before multipliers.
function BaseService.placedIncome(player)
	local base = playerBase[player]
	if not base then
		return 0
	end
	local total = 0
	for _, pedestal in ipairs(base.Pedestals) do
		if pedestal.Model then
			total = total + (pedestal.Model:GetAttribute("Rate") or 0)
		end
	end
	return total
end

-- Is this position inside any lapak zone? The tsunami spares those players.
function BaseService.isOnAnyBase(position)
	for _, base in ipairs(bases) do
		if math.abs(position.X - base.Center.X) <= 13 and math.abs(position.Z - base.Center.Z) <= 10 then
			return true
		end
	end
	return false
end

-- Drop everything a player carries: welds off, models handed back so the
-- caller can send them to the conveyor.
function BaseService.dropCarried(player)
	local list = carried[player] or {}
	carried[player] = {}
	for _, model in ipairs(list) do
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("WeldConstraint") then
				descendant:Destroy()
			end
		end
	end
	refreshCarriedNames(player)
	return list
end

-- The placement loop (four times a second) and the lock display loop (twice
-- a second, keeping every sign's TERKUNCI countdown in sync).
function BaseService.startLoops()
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, player in ipairs(Players:GetPlayers()) do
				pcall(tryPlace, player)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = os.time()
			for _, base in ipairs(bases) do
				if base.LockedUntil > now then
					base.LockLabel.Text = "TERKUNCI " .. (base.LockedUntil - now) .. " dtk"
					base.LockLabel.Visible = true
				else
					base.LockLabel.Visible = false
				end
			end
		end
	end)
end

return BaseService
