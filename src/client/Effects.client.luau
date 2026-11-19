-- Effects.client.luau
-- Juice only: particle bursts on buy, place, steal and rebirth, the tsunami
-- banner with screen shake and a blue vignette, and the knockback that flings
-- the local character. No uploaded sounds or images: everything is built
-- from parts, emitters and labels.
--
-- The knockback runs here, on the client, on purpose: the server only sends
-- the velocity. A velocity the server sets on a client-owned character is
-- overwritten by the client's own physics, so the client has to set its own
-- HumanoidRootPart velocity and force freefall, or the ground fights the fling.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Notify = Remotes:WaitForChild("Notify")
local WaveSignal = Remotes:WaitForChild("WaveSignal")
local Knockback = Remotes:WaitForChild("Knockback")

local gui = Instance.new("ScreenGui")
gui.Name = "PasarBrainrotEffects"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local function myPosition()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		return root.Position + Vector3.new(0, 2, 0)
	end
	return Vector3.new(0, 5, 0)
end

-- A one-shot burst of coloured particles at a world position: a tiny
-- invisible anchored part carries the emitter, then cleans itself up.
local function burstAt(position, color, count)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.5, 0.5, 0.5)
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new(0.6)
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Speed = NumberRange.new(6, 14)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(count or 24)
	task.delay(1.5, function()
		anchor:Destroy()
	end)
end

-- A big word that floats up and fades, for rebirths.
local function floatText(text, color)
	local label = Instance.new("TextLabel")
	label.Text = text
	label.Font = Enum.Font.LuckiestGuy
	label.TextSize = 44
	label.TextColor3 = color
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Size = UDim2.new(0, 400, 0, 60)
	label.Position = UDim2.new(0.5, 0, 0.35, 0)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	local tween = TweenService:Create(label, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.25, 0),
		TextTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

-- The tsunami banner: large, centred, near the top of the screen.
local banner = Instance.new("TextLabel")
banner.Size = UDim2.new(0, 700, 0, 60)
banner.Position = UDim2.new(0.5, -350, 0, 140)
banner.BackgroundTransparency = 1
banner.Font = Enum.Font.LuckiestGuy
banner.TextSize = 36
banner.TextStrokeTransparency = 0.2
banner.Visible = false
banner.Parent = gui

-- A thick blue border around the screen while the wave sweeps.
local vignette = Instance.new("Frame")
vignette.Size = UDim2.new(1, 0, 1, 0)
vignette.BackgroundTransparency = 1
vignette.Visible = false
vignette.Parent = gui
local vignetteStroke = Instance.new("UIStroke")
vignetteStroke.Color = Color3.fromRGB(60, 140, 255)
vignetteStroke.Thickness = 24
vignetteStroke.Transparency = 0.5
vignetteStroke.Parent = vignette

-- Screen shake, applied after the camera's own update every frame so it is
-- not overwritten. The wave shakes gently; a knockback jolts hard and brief.
local shaking = false
local joltUntil = 0
RunService:BindToRenderStep("PasarBrainrotShake", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local now = os.clock()
	if shaking then
		camera.CFrame = camera.CFrame * CFrame.new(math.random(-30, 30) / 100, math.random(-30, 30) / 100, 0)
	elseif now < joltUntil then
		camera.CFrame = camera.CFrame * CFrame.new(math.random(-60, 60) / 100, math.random(-60, 60) / 100, 0)
	end
end)

WaveSignal.OnClientEvent:Connect(function(phase)
	if phase == "warn" then
		banner.Text = "GEROBAK TSUNAMI DATANG! LARI KE LAPAK!"
		banner.TextColor3 = Color3.fromRGB(255, 183, 3)
		banner.Visible = true
	elseif phase == "wave" then
		banner.Text = "GEROBAK TSUNAMI!"
		banner.TextColor3 = Color3.fromRGB(80, 160, 255)
		banner.Visible = true
		shaking = true
		vignette.Visible = true
	elseif phase == "clear" then
		banner.Visible = false
		shaking = false
		vignette.Visible = false
	end
end)

-- Bursts follow the notification kinds the server sends.
Notify.OnClientEvent:Connect(function(_, kind)
	if kind == "buy" then
		burstAt(myPosition(), Color3.fromRGB(120, 255, 140), 24)
	elseif kind == "place" then
		burstAt(myPosition(), Color3.fromRGB(255, 183, 3), 28)
	elseif kind == "steal" then
		burstAt(myPosition(), Color3.fromRGB(255, 77, 109), 28)
	elseif kind == "rebirth" then
		local pos = myPosition()
		burstAt(pos, Color3.fromRGB(255, 183, 3), 30)
		burstAt(pos, Color3.fromRGB(76, 201, 240), 30)
		burstAt(pos, Color3.fromRGB(255, 77, 109), 30)
		floatText("REBIRTH!", Color3.fromRGB(255, 183, 3))
	end
end)

-- The tsunami's fling: set our own velocity, force freefall, jolt the
-- camera, burst blue.
Knockback.OnClientEvent:Connect(function(velocity)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root then
		root.AssemblyLinearVelocity = velocity
	end
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	joltUntil = os.clock() + 0.4
	burstAt(myPosition(), Color3.fromRGB(80, 160, 255), 30)
end)
