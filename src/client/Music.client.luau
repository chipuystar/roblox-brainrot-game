-- Pasar Brainrot: background music.
-- One looping track ("Happy Song", APM Music) plays from SoundService for
-- the whole session. The Sound lives outside the character, and this script
-- bails out early if the Sound already exists, so a respawn never restarts
-- the track, never duplicates it, and never undoes the player's mute.
-- The HUD's music button talks to this script through a BindableEvent
-- named "MusicToggle" in ReplicatedStorage.

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TRACK_SOUND_ID = "rbxassetid://1843404009"
local MUSIC_VOLUME = 0.5
local SOUND_NAME = "PasarBrainrotMusic"
local TOGGLE_NAME = "MusicToggle"

-- Already set up (this script re-runs on respawn): keep the existing Sound
-- and its playback state exactly as they are.
if SoundService:FindFirstChild(SOUND_NAME) then
	return
end

local music = Instance.new("Sound")
music.Name = SOUND_NAME
music.SoundId = TRACK_SOUND_ID
music.Looped = true
music.Volume = MUSIC_VOLUME
music.Parent = SoundService
music:Play()

local toggle = ReplicatedStorage:FindFirstChild(TOGGLE_NAME)
if not toggle then
	toggle = Instance.new("BindableEvent")
	toggle.Name = TOGGLE_NAME
	toggle.Parent = ReplicatedStorage
end

toggle.Event:Connect(function()
	if music.IsPlaying then
		music:Pause()
	else
		music:Play()
	end
end)
