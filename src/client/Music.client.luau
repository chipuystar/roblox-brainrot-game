-- Music.client.luau
-- Background music for Pasar Brainrot: a looping track that starts when the
-- client loads, with a mute toggle driven by the MUSIK button in GameUI.
-- The Sound lives in SoundService (never under the character), so it keeps
-- playing through respawns.

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TRACK_ID = "rbxassetid://1843404009" -- "Happy Song" (APM Music)
local SOUND_NAME = "PasarBrainrotMusic"
local TOGGLE_EVENT_NAME = "MusicToggle"
local VOLUME = 0.5

-- StarterPlayerScripts re-runs this script on every respawn. If the Sound is
-- already there, leave it alone: never restart the track, never stack a
-- second copy on top, and never undo the player's mute.
local music = SoundService:FindFirstChild(SOUND_NAME)
if not music then
	music = Instance.new("Sound")
	music.Name = SOUND_NAME
	music.SoundId = TRACK_ID
	music.Looped = true
	music.Volume = VOLUME
	music.Parent = SoundService
	music:Play()
end

-- One shared event for the mute button. Find it, or create it here, so the
-- button works even if it is built before this script runs.
local toggleEvent = ReplicatedStorage:FindFirstChild(TOGGLE_EVENT_NAME)
if not toggleEvent then
	toggleEvent = Instance.new("BindableEvent")
	toggleEvent.Name = TOGGLE_EVENT_NAME
	toggleEvent.Parent = ReplicatedStorage
end

toggleEvent.Event:Connect(function()
	if music.Playing then
		music:Pause()
	else
		music:Play()
	end
end)
