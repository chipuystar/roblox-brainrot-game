-- Music: owns the background track. "Happy Song" by APM Music / Justement Music,
-- looping, keeps playing through respawns (this script runs in
-- StarterPlayerScripts and is never tied to the character). The MUSIK button in
-- the HUD fires the MusicToggle event to pause and resume it.
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TRACK_ID = "rbxassetid://1843404009"

local music = SoundService:FindFirstChild("PasarBrainrotMusic")
if not music then
	music = Instance.new("Sound")
	music.Name = "PasarBrainrotMusic"
	music.SoundId = TRACK_ID
	music.Looped = true
	music.Volume = 0.5
	music.Parent = SoundService
	music:Play()
end
-- When the Sound already exists (a client re-run), the track is left exactly
-- as it is: never restarted, never duplicated, never un-muted.

local toggle = ReplicatedStorage:FindFirstChild("MusicToggle")
if not toggle then
	toggle = Instance.new("BindableEvent")
	toggle.Name = "MusicToggle"
	toggle.Parent = ReplicatedStorage
end

toggle.Event:Connect(function()
	if music.Playing then
		music:Pause()
	else
		music:Resume()
	end
end)
