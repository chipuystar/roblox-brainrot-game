-- Music.client.luau — background music for Pasar Brainrot.
-- Plays a looping track in SoundService and toggles it on the MusicToggle
-- BindableEvent. The Sound lives in SoundService, not under the character,
-- so the music keeps playing through respawns.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local TRACK_ID = "rbxassetid://1843404009" -- "Happy Song", APM Music
local SOUND_NAME = "PasarBrainrotMusic"
local VOLUME = 0.5

-- If the track is already set up (this script re-ran after a respawn), leave
-- it exactly as it is: never restart it, never duplicate it, never undo a
-- mute the player chose.
if SoundService:FindFirstChild(SOUND_NAME) then
	return
end

local music = Instance.new("Sound")
music.Name = SOUND_NAME
music.SoundId = TRACK_ID
music.Looped = true
music.Volume = VOLUME
music.Parent = SoundService
music:Play()

-- The mute button fires this event; each fire flips the track between paused
-- and playing. Create the event here so it exists from load; the button
-- finds it (or creates it itself if this script has not run yet).
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
		music:Play()
	end
end)
