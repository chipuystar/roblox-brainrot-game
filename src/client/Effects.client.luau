-- Effects: juice only. Particle bursts on buy, place, steal and rebirth, the
-- tsunami banner, screen shake, the blue vignette, and the client-side
-- knockback fling (a server-set velocity is overwritten by client physics, so
-- the server only tells the client and the client moves itself).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = Instance.new("ScreenGui")
gui.Name = "PasarBrainrotEffects"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("TextLabel")
banner.Name = "TsunamiBanner"
banner.BackgroundTransparency = 1
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 140)
banner.Size = UDim2.fromOffset(700, 48)
banner.Font = Enum.Font.LuckiestGuy
banner.TextSize = 32
banner.TextColor3 = Color3.fromRGB(255, 183, 3)
banner.TextStrokeTransparency = 0.4
banner.Visible = false
banner.Parent = gui

local vignette = Instance.new("Frame")
vignette.Name = "WaveVignette"
vignette.BackgroundTransparency = 1
vignette.Size = UDim2.fromScale(1, 1)
vignette.BorderSizePixel = 0
vignette.Visible = false
vignette.Parent = gui
local vignetteStroke = Instance.new("UIStroke")
vignetteStroke.Color = Color3.fromRGB(80, 160, 255)
vignetteStroke.Thickness = 14
vignetteStroke.Transparency = 0.35
vignetteStroke.Parent = vignette

-- A one-shot burst of coloured particles at a world position.
local function burst(position, color, count)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new(0.6)
	emitter.Speed = NumberRange.new(6, 12)
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(count or 24)
	task.delay(1.2, function()
		anchor:Destroy()
	end)
end

local function playerPosition()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		return root.Position + Vector3.new(0, 2, 0)
	end
	return Vector3.new(0, 5, 0)
end

local function floatingText(text, color)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local tag = Instance.new("BillboardGui")
	tag.Adornee = root
	tag.Size = UDim2.fromOffset(300, 60)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	tag.AlwaysOnTop = true
	tag.LightInfluence = 0
	tag.Parent = root
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.Font = Enum.Font.LuckiestGuy
	textLabel.TextSize = 36
	textLabel.TextColor3 = color
	textLabel.TextStrokeTransparency = 0.4
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.Parent = tag
	task.spawn(function()
		for i = 1, 20 do
			tag.StudsOffsetWorldSpace += Vector3.new(0, 0.15, 0)
			textLabel.TextTransparency = i / 20
			task.wait(0.05)
		end
		tag:Destroy()
	end)
end

local shakeConnection = nil
local function startShake()
	if shakeConnection then
		return
	end
	shakeConnection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if camera then
			camera.CFrame *= CFrame.new(math.random(-15, 15) / 100, math.random(-15, 15) / 100, 0)
		end
	end)
end

local function stopShake()
	if shakeConnection then
		shakeConnection:Disconnect()
		shakeConnection = nil
	end
end

remotes.WaveSignal.OnClientEvent:Connect(function(phase)
	if phase == "warn" then
		banner.Text = "GEROBAK TSUNAMI DATANG! LARI KE LAPAK!"
		banner.TextColor3 = Color3.fromRGB(255, 183, 3)
		banner.Visible = true
	elseif phase == "wave" then
		banner.Text = "GEROBAK TSUNAMI!"
		banner.TextColor3 = Color3.fromRGB(120, 190, 255)
		banner.Visible = true
		vignette.Visible = true
		startShake()
	elseif phase == "clear" then
		banner.Visible = false
		vignette.Visible = false
		stopShake()
	end
end)

remotes.Notify.OnClientEvent:Connect(function(_text, kind)
	if kind == "buy" then
		burst(playerPosition(), Color3.fromRGB(120, 255, 140))
	elseif kind == "place" then
		burst(playerPosition(), Color3.fromRGB(255, 183, 3))
	elseif kind == "steal" then
		burst(playerPosition(), Color3.fromRGB(255, 77, 109))
	elseif kind == "rebirth" then
		local pos = playerPosition()
		burst(pos, Color3.fromRGB(255, 183, 3), 30)
		burst(pos, Color3.fromRGB(76, 201, 240), 30)
		burst(pos, Color3.fromRGB(255, 77, 109), 30)
		floatingText("REBIRTH!", Color3.fromRGB(255, 183, 3))
	end
end)

remotes.Knockback.OnClientEvent:Connect(function(velocity)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root then
		return
	end
	root.AssemblyLinearVelocity = velocity
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	local camera = workspace.CurrentCamera
	if camera then
		camera.CFrame *= CFrame.new(0, 1.2, 0)
	end
	burst(root.Position, Color3.fromRGB(120, 190, 255), 30)
end)
