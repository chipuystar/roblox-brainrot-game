-- BaseService: lapak assignment, carrying, placement, locking and stealing.
-- A player buys a brainrot off the belt, carries it home above their head, and
-- it earns money once it stands on one of their six pedestals.
local Config = require(script.Parent.Config)
local MoneyService = require(script.Parent.MoneyService)

local BaseService = {}

local Workspace = game:GetService("Workspace")

local bases = {}
local spawner = nil
local remotes = nil
local carriedBy = {} -- [player] = { models carried above their head }

local function notify(player, text, kind)
	if remotes then
		remotes.Notify:FireClient(player, text, kind)
	end
end

local function inZone(position, base)
	return math.abs(position.X - base.Center.X) <= Config.BASE_WIDTH / 2
		and math.abs(position.Z - base.Center.Z) <= Config.BASE_DEPTH / 2
end

local function getBase(player)
	for _, base in ipairs(bases) do
		if base.Owner == player then
			return base
		end
	end
	return nil
end

local function syncCarriedNames(player)
	local names = {}
	for _, model in ipairs(carriedBy[player] or {}) do
		table.insert(names, model:GetAttribute("CharName"))
	end
	player:SetAttribute("CarriedNames", table.concat(names, ", "))
end

function BaseService.init(baseList, spawnerModule, remoteFolder)
	bases = baseList
	spawner = spawnerModule
	remotes = remoteFolder
end

-- A tall glowing beam plus a floating LAPAKMU tag, so the player can find their
-- own lapak from across the market.
local function createBeacon(base)
	local beam = Instance.new("Part")
	beam.Name = "BaseBeacon"
	beam.Anchored = true
	beam.CanCollide = false
	beam.Size = Vector3.new(1.5, 13, 1.5)
	beam.CFrame = CFrame.new(base.Center.X, 7, base.Center.Z)
	beam.Color = base.Color
	beam.Material = Enum.Material.Neon
	beam.Transparency = 0.5
	beam.Parent = Workspace
	local tag = Instance.new("BillboardGui")
	tag.Adornee = beam
	tag.Size = UDim2.fromOffset(160, 40)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 7.5, 0)
	tag.AlwaysOnTop = true
	tag.LightInfluence = 0
	tag.Parent = beam
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = "LAPAKMU"
	label.Font = Enum.Font.LuckiestGuy
	label.TextSize = 24
	label.TextColor3 = base.Color
	label.TextStrokeTransparency = 0.5
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Parent = tag
	base.Beacon = beam
end

function BaseService.assignBase(player)
	for _, base in ipairs(bases) do
		if base.Owner == nil then
			base.Owner = player
			base.SignOwner.Text = player.DisplayName
			player:SetAttribute("BaseIndex", base.Index)
			createBeacon(base)
			return base
		end
	end
	return nil
end

function BaseService.freeBase(player)
	local base = getBase(player)
	if not base then
		return
	end
	for _, pedestal in ipairs(base.Pedestals) do
		if pedestal.Occupant then
			pedestal.Occupant:Destroy()
			pedestal.Occupant = nil
		end
	end
	base.Owner = nil
	base.LockedUntil = 0
	base.LockCooldownUntil = 0
	base.SignOwner.Text = "Kosong"
	base.SignLock.Visible = false
	if base.Beacon then
		base.Beacon:Destroy()
		base.Beacon = nil
	end
	player:SetAttribute("BaseIndex", 0)
	player:SetAttribute("BaseLockedUntil", 0)
end

-- Roblox does not hold a model's parts together on its own: weld every part to
-- the PrimaryPart, or only the PrimaryPart rides and the rest falls through.
local function weldModelTogether(model)
	local primary = model.PrimaryPart
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant ~= primary then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = primary
			weld.Part1 = descendant
			weld.Parent = primary
		end
	end
end

local function destroyWelds(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("WeldConstraint") then
			descendant:Destroy()
		end
	end
end

function BaseService.carry(player, model)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return false
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.Massless = true
		end
	end
	weldModelTogether(model)
	local prompt = model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end
	-- Stack by measured size: the first rides 1.2 above the head, each next one
	-- on top of the previous with a small gap.
	local carried = carriedBy[player] or {}
	local bottom = head.Position.Y + head.Size.Y / 2 + 1.2
	for _, other in ipairs(carried) do
		bottom += other:GetAttribute("BottomOffset") + other:GetAttribute("TopOffset") + 0.3
	end
	local pivotY = bottom + model:GetAttribute("BottomOffset")
	model:PivotTo(CFrame.new(head.Position.X, pivotY, head.Position.Z))
	local attach = Instance.new("WeldConstraint")
	attach.Part0 = head
	attach.Part1 = model.PrimaryPart
	attach.Parent = model.PrimaryPart
	table.insert(carried, model)
	carriedBy[player] = carried
	model:SetAttribute("State", "carried")
	model:SetAttribute("Owner", tostring(player.UserId))
	syncCarriedNames(player)
	return true
end

local function placeModel(player, base, model, pedestal)
	destroyWelds(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
	-- Face the market centre: north lapak face +Z, south lapak face -Z.
	local yaw = base.Center.Z < 0 and 0 or math.rad(180)
	model:PivotTo(CFrame.new(
		pedestal.Top.X,
		pedestal.Top.Y + model:GetAttribute("BottomOffset") + 0.05,
		pedestal.Top.Z
	) * CFrame.Angles(0, yaw, 0))
	pedestal.Occupant = model
	model:SetAttribute("State", "placed")
	model:SetAttribute("Owner", tostring(player.UserId))
	local prompt = model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.ActionText = "AMBIL"
		prompt.Enabled = true
	end
	local tag = model.PrimaryPart:FindFirstChild("NameTag")
	if tag then
		local priceLine = tag:FindFirstChild("PriceLine")
		if priceLine then
			priceLine.Visible = false
		end
	end
	local carried = carriedBy[player] or {}
	for i, other in ipairs(carried) do
		if other == model then
			table.remove(carried, i)
			break
		end
	end
	syncCarriedNames(player)
	notify(player, model:GetAttribute("CharName") .. " ditaruh! +$" .. model:GetAttribute("Rate") .. "/detik", "place")
end

local function firstFreePedestal(base)
	for _, pedestal in ipairs(base.Pedestals) do
		if pedestal.Occupant == nil then
			return pedestal
		end
	end
	return nil
end

-- Every quarter second, players carrying brainrots inside their own lapak zone
-- place them on the first free pedestals. One bad model must never kill the loop.
local function placementLoop()
	task.spawn(function()
		while true do
			task.wait(0.25)
			for player, carried in pairs(carriedBy) do
				if #carried > 0 then
					local base = getBase(player)
					local character = player.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if base and root and inZone(root.Position, base) then
						for _, model in ipairs(table.clone(carried)) do
							local pedestal = firstFreePedestal(base)
							if pedestal then
								pcall(placeModel, player, base, model, pedestal)
							else
								notify(player, "Lapak penuh!", "bad")
								break
							end
						end
					end
				end
			end
		end
	end)
end

function BaseService.lockBase(player)
	local base = getBase(player)
	if not base then
		return false, "Kamu belum punya lapak!"
	end
	local now = os.time()
	if base.LockedUntil > now then
		return false, "Lapak sudah terkunci!"
	end
	if base.LockCooldownUntil > now then
		return false, "Kunci masih cooldown " .. (base.LockCooldownUntil - now) .. " detik!"
	end
	base.LockedUntil = now + Config.LOCK.Duration
	base.LockCooldownUntil = now + Config.LOCK.Duration + Config.LOCK.Cooldown
	player:SetAttribute("BaseLockedUntil", base.LockedUntil)
	return true, "Lapak terkunci 30 detik!"
end

local function lockDisplayLoop()
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = os.time()
			for _, base in ipairs(bases) do
				if base.LockedUntil > now then
					base.SignLock.Text = "TERKUNCI " .. (base.LockedUntil - now) .. " dtk"
					base.SignLock.Visible = true
				else
					base.SignLock.Visible = false
				end
			end
		end
	end)
end

local function takePlaced(player, model)
	local ownerId = model:GetAttribute("Owner")
	local state = MoneyService.getState(player)
	local carried = carriedBy[player] or {}
	if state and #carried >= state.CarryCap then
		notify(player, "Tangan penuh!", "bad")
		return
	end
	local wasSteal = ownerId ~= "" and ownerId ~= tostring(player.UserId)
	if wasSteal then
		for _, base in ipairs(bases) do
			if base.Owner and tostring(base.Owner.UserId) == ownerId and base.LockedUntil > os.time() then
				notify(player, "Lapak itu terkunci!", "bad")
				return
			end
		end
	end
	for _, base in ipairs(bases) do
		for _, pedestal in ipairs(base.Pedestals) do
			if pedestal.Occupant == model then
				pedestal.Occupant = nil
			end
		end
	end
	local victim = nil
	if wasSteal then
		for _, base in ipairs(bases) do
			if base.Owner and tostring(base.Owner.UserId) == ownerId then
				victim = base.Owner
			end
		end
	end
	if BaseService.carry(player, model) then
		if wasSteal then
			notify(player, "Kamu mencuri " .. model:GetAttribute("CharName") .. "!", "steal")
			if victim then
				notify(victim, model:GetAttribute("CharName") .. " dicuri " .. player.DisplayName .. "!", "bad")
			end
		else
			notify(player, "Kamu mengambil " .. model:GetAttribute("CharName") .. ".", "info")
		end
	end
end

-- One prompt per brainrot for its whole life: on the conveyor it buys, on a
-- lapak it takes (steal from others, pick up your own).
function BaseService.handlePrompt(player, model)
	local character = player.Character
	if not character or not character:FindFirstChild("Head") then
		return
	end
	local stateName = model:GetAttribute("State")
	if stateName == "conveyor" then
		local state = MoneyService.getState(player)
		local carried = carriedBy[player] or {}
		if state and #carried >= state.CarryCap then
			notify(player, "Tangan penuh!", "bad")
			return
		end
		local price = model:GetAttribute("Price")
		if not MoneyService.spend(player, price) then
			notify(player, "Uang tidak cukup! Butuh $" .. price .. ".", "bad")
			return
		end
		spawner.removeFromBelt(model)
		if BaseService.carry(player, model) then
			notify(player, "Kamu membeli " .. model:GetAttribute("CharName") .. "!", "buy")
		end
	elseif stateName == "placed" then
		takePlaced(player, model)
	end
end

function BaseService.placedIncome(player)
	local base = getBase(player)
	if not base then
		return 0
	end
	local total = 0
	for _, pedestal in ipairs(base.Pedestals) do
		if pedestal.Occupant then
			total += pedestal.Occupant:GetAttribute("Rate")
		end
	end
	return total
end

-- Drops everything the player carries; the caller sends the models back to the belt.
function BaseService.dropAll(player)
	local carried = carriedBy[player] or {}
	carriedBy[player] = {}
	player:SetAttribute("CarriedNames", "")
	for _, model in ipairs(carried) do
		destroyWelds(model)
	end
	return carried
end

function BaseService.isInAnyBase(position)
	for _, base in ipairs(bases) do
		if inZone(position, base) then
			return true
		end
	end
	return false
end

function BaseService.startLoops()
	placementLoop()
	lockDisplayLoop()
end

return BaseService
