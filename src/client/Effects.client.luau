-- Pasar Brainrot: juice. Particle bursts on buy/place/steal/rebirth, the
-- tsunami warning banner, screen shake and a blue vignette while the wave
-- sweeps the market. Visual only: no uploaded sounds or images.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local playerGui = player:WaitForChild("PlayerGui")

local function getPlayerPosition()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		return root.Position
	end
	return Vector3.new(0, 5, 0)
end

-- A one-shot burst of particles at a world position.
local function burst(position, color, count, speed)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position
	anchor.Parent = Workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new(0.6)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.Lifetime = NumberRange.new(0.4, 0.9)
	emitter.Rate = 0
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Transparency = NumberSequence.new(0.2)
	emitter.Parent = anchor
	emitter:Emit(count)
	task.delay(1.5, function()
		anchor:Destroy()
	end)
end

-- Floating text that rises and fades, for big moments.
local function floatingText(position, text, color, size)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position
	anchor.Parent = Workspace
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(320, 60)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = size or 26
	label.Font = Enum.Font.LuckiestGuy
	label.TextStrokeTransparency = 0.1
	label.Parent = gui
	TweenService:Create(gui, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = Vector3.new(0, 6, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1.4), { TextTransparency = 1 }):Play()
	task.delay(1.5, function()
		anchor:Destroy()
	end)
end

-- Tsunami banner + red vignette, both hidden until the wave comes.
local fxGui = Instance.new("ScreenGui")
fxGui.Name = "PasarBrainrotFX"
fxGui.IgnoreGuiInset = true
fxGui.ResetOnSpawn = false
fxGui.DisplayOrder = 20
fxGui.Parent = playerGui

local banner = Instance.new("TextLabel")
banner.Name = "WaveBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 140)
banner.Size = UDim2.fromOffset(620, 56)
banner.BackgroundTransparency = 1
banner.Text = ""
banner.TextColor3 = Color3.fromRGB(0, 170, 255)
banner.TextSize = 34
banner.Font = Enum.Font.LuckiestGuy
banner.TextStrokeTransparency = 0.1
banner.Visible = false
banner.Parent = fxGui

local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundTransparency = 1
vignette.Visible = false
vignette.Parent = fxGui
local vignetteStroke = Instance.new("UIStroke")
vignetteStroke.Color = Color3.fromRGB(0, 170, 255)
vignetteStroke.Thickness = 28
vignetteStroke.Transparency = 0.45
vignetteStroke.Parent = vignette

-- Screen shake, applied after the camera update each frame.
local shakeStrength = 0
RunService:BindToRenderStep("PasarBrainrotShake", Enum.RenderPriority.Camera.Value + 1, function()
	if shakeStrength > 0 then
		local camera = Workspace.CurrentCamera
		if camera then
			camera.CFrame = camera.CFrame * CFrame.new(
				(math.random() - 0.5) * shakeStrength,
				(math.random() - 0.5) * shakeStrength,
				0
			)
		end
	end
end)

local function showBanner(text, color)
	banner.Text = text
	banner.TextColor3 = color
	banner.Visible = true
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), { TextSize = 38 }):Play()
end

local function hideBanner()
	banner.Visible = false
end

remotes.WaveSignal.OnClientEvent:Connect(function(phase)
	if phase == "warning" then
		showBanner("GEROBAK TSUNAMI DATANG! LARI KE LAPAK!", Color3.fromRGB(255, 180, 60))
	elseif phase == "wave" then
		showBanner("GEROBAK TSUNAMI!", Color3.fromRGB(0, 170, 255))
		shakeStrength = 0.45
		vignette.Visible = true
	elseif phase == "clear" then
		hideBanner()
		shakeStrength = 0
		vignette.Visible = false
	end
end)

-- The tsunami fling, applied HERE on the client: the player owns their
-- own character's physics, so a velocity set on the server gets
-- overwritten and the player only hops. Setting it on the client's own
-- HumanoidRootPart makes the fling actually land.
remotes.Knockback.OnClientEvent:Connect(function(velocity)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root then
		root.AssemblyLinearVelocity = velocity
	end
	if humanoid then
		-- Freefall so the humanoid's ground physics does not fight the fling.
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	-- A hard camera jolt and a blue burst sell the impact.
	shakeStrength = 1.2
	local pos = getPlayerPosition()
	burst(pos + Vector3.new(0, 2, 0), Color3.fromRGB(0, 170, 255), 30, 16)
end)

remotes.Notify.OnClientEvent:Connect(function(text, kind)
	local pos = getPlayerPosition()
	if kind == "buy" then
		burst(pos + Vector3.new(0, 3, 0), Color3.fromRGB(120, 255, 140), 24, 12)
	elseif kind == "place" then
		burst(pos + Vector3.new(0, 2, 0), Color3.fromRGB(255, 183, 3), 30, 10)
	elseif kind == "steal" then
		burst(pos + Vector3.new(0, 3, 0), Color3.fromRGB(255, 77, 109), 24, 14)
	elseif kind == "rebirth" then
		burst(pos + Vector3.new(0, 4, 0), Color3.fromRGB(255, 183, 3), 40, 16)
		burst(pos + Vector3.new(0, 4, 0), Color3.fromRGB(76, 201, 240), 30, 14)
		burst(pos + Vector3.new(0, 4, 0), Color3.fromRGB(255, 77, 109), 30, 14)
		floatingText(pos, "REBIRTH!", Color3.fromRGB(255, 183, 3), 34)
	end
end)
