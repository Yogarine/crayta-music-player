--------------------------------------------------------------------------------------------------------
-- @module    Yogarine.MusicPlayer
-- @author    Alwin "Yogarine" Garside <alwin@garsi.de>
-- @copyright 2020 Alwin Garside
-- @license   https://opensource.org/licenses/BSD-2-Clause 2-Clause BSD License
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
-- @type MusicPlayerScript
-- @todo Fade-in
--------------------------------------------------------------------------------------------------------

---
-- @field properties Properties: Holds the values that have been set on an instance of a script.
---
local MusicPlayerScript = {
	PROPERTY_PLAY          = "PLAY",
	PROPERTY_PREV_NEXT     = "PREV | NEXT",
	PROPERTY_QUEUE         = "Queue",
	PROPERTY_PLAYLIST      = "Active Playlist",
	PROPERTY_SONG_DURATION = "Song Duration"
}

---
-- Script properties are defined here.
---
MusicPlayerScript.Properties = {
	{
		name                = MusicPlayerScript.PROPERTY_PLAY,
		type                = "boolean",
		tooltip             = "Play / Stop music playback",
	},
	{
		name                = MusicPlayerScript.PROPERTY_PREV_NEXT,
		type                = "number",
		tooltip             = "Skip to the next / previous song by pressing the +/- buttons",
		default             = 1
	},
	{
		name                = MusicPlayerScript.PROPERTY_QUEUE,
		type                = "soundasset",
		tooltip             = "Songs to play.",
		container           = "array"
	},
	{
		name                = MusicPlayerScript.PROPERTY_PLAYLIST,
		type                = "entity",
		tooltip             = "Active Playlist.",
	},
	{
		name                = MusicPlayerScript.PROPERTY_SONG_DURATION,
		type                = "number",
		tooltip             = "Default song duration",
		default             = 150,
		editor              = "seconds"
	},
	{
		name                = "currentQueuePosition",
		type                = "number",
		allowFloatingPoint  = false,
		editable            = false,
		default             = 0
	},
	{
		name                = "currentPlaylistPosition",
		type                = "number",
		allowFloatingPoint  = false,
		editable            = false,
		default             = 0
	},
	{
		name                = "currentSongDuration",
		type                = "number",
		editable            = false,
		default             = 0
	},
}

---
-- Initializes all the fields on this instance.
---
function MusicPlayerScript:InitFields()
	Printf("MusicPlayer: InitFields")
	local entity = self:GetEntity()

	---
	-- !Util: Yogarine's Util class.
	---
	self.Util = entity.util

	---
	-- number: Current song's play time.
	---
	self.currentSongProgress = 0

	if IsClient() then
		---
		-- number: Current position in queue.
		---
		self.currentQueuePosition = 0

		---
		-- number: Current position in playlist.
		---
		self.currentPlaylistPosition = 0

		---
		-- number: Current song's duration.
		---
		self.currentSongDuration = self.properties.currentSongDuration or self.properties[MusicPlayerScript.PROPERTY_SONG_DURATION]

		---
		-- bool: Wether this MusicPlayer is connected to the server.
		---
		self.connected = true
	end

	---
	-- bool: Manually keep track of active state, because we don't want to override the
	--       client active state by toggling the entity's active property on the server.
	---
	self.active = entity.active

	self.offset = self.properties[MusicPlayerScript.PROPERTY_PREV_NEXT]
end

---
-- This function is called on the server when this entity is created.
---
function MusicPlayerScript:Init()
	Printf("MusicPlayer: Init")
	self:InitFields()

	self.properties.currentQueuePosition = 0
	self.properties.currentSongDuration  = self.properties[MusicPlayerScript.PROPERTY_SONG_DURATION]

	if self.properties[MusicPlayerScript.PROPERTY_PLAY] then
		self:Play()
	end
end

---
-- This function is called on the client when this entity is created
---
function MusicPlayerScript:ClientInit()
	Printf("MusicPlayer: ClientInit")
	self:InitFields()

	if not self.connected and self.properties[MusicPlayerScript.PROPERTY_PLAY] then
		self:Play()
	end
end

---
-- Called each frame on the server.
--
-- @tparam  number  deltaTimeSeconds  Time elapsed since the last frame was rendered.
---
function MusicPlayerScript:OnTick(deltaTimeSeconds)
	-- Check if play state has changed.
	local play = self.properties[MusicPlayerScript.PROPERTY_PLAY]
	--	Printf("active: {1}, play: {2}", self.active, play)
	if self.active ~= play then
		if play then
			self:Play()
		else
			self:Stop()
		end
	end

	--Printf("offset: {1}", self.properties[MusicPlayerScript.PROPERTY_PREV_NEXT])
	if self.offset ~= self.properties[MusicPlayerScript.PROPERTY_PREV_NEXT] then
		if self.properties[MusicPlayerScript.PROPERTY_PREV_NEXT] > self.offset then
			self:Next()
		else
			self:Previous()
		end

		self.offset = self.properties[MusicPlayerScript.PROPERTY_PREV_NEXT]
	end



	if self.active then
		self.currentSongProgress = self.currentSongProgress + deltaTimeSeconds
	end

	if self.currentSongProgress >= self.properties.currentSongDuration then
		self:Next()
	end
end

---
-- Called each frame on the client.
--
-- @tparam  number  deltaTimeSeconds  Time elapsed since the last frame was rendered.
---
function MusicPlayerScript:ClientOnTick(deltaTimeSeconds)
	if self:GetEntity().active then
		self.currentSongProgress = self.currentSongProgress + deltaTimeSeconds
	end

	if not self.connected then
		if self.currentSongProgress >= self.currentSongDuration then
			self:Next()
		end
	end
end

---
-- Get the current song.
--
-- @treturn ?number
---
function MusicPlayerScript:GetCurrentQueuePosition()
	local position
	if IsServer() or self.connected then
		if 0 == self.properties.currentQueuePosition then
			return nil
		end

		position = self.properties.currentQueuePosition
	else
		position = self.currentQueuePosition
	end

	Printf("MusicPlayer: GetCurrentQueuePosition: {1}", song)

	return position
end

---
-- Set the current song.
--
-- @tparam  ?number  song
---
function MusicPlayerScript:SetCurrentQueuePosition(song)
	if nil == song then
		song = 0
	end

	if IsServer() then
		if self.properties.currentQueuePosition ~= song then
			Printf("MusicPlayer: Setting currentQueuePosition to {1}", song)
			self.properties.currentQueuePosition = song
			-- TODO: figure out way to declare song Durations in playlists.
			self.properties.currentSongDuration = self.properties[MusicPlayerScript.PROPERTY_SONG_DURATION]
			self.currentSongProgress = 0
		end
	else
		if self.connected then
			if self.properties.currentQueuePosition ~= song then
				self:SendToServer("SetCurrentQueuePosition", song)
				self.currentSongProgress = 0
			end
		else
			if self.currentQueuePosition ~= song then
				Printf("MusicPlayer: Setting currentQueuePosition to {1}", song)
				self.currentQueuePosition = song
				-- TODO: figure out way to declare song Durations in playlists.
				self.currentSongDuration = self.properties[MusicPlayerScript.PROPERTY_SONG_DURATION]
				self.currentSongProgress = 0
			end
		end
	end
end

---
-- @treturn SoundAsset
---
function MusicPlayerScript:ClientGetSound()
	assert(IsClient(), "MusicPlayer: ClientGetSound() should only be called from the Client.")

	return self:GetEntity().sound
end

---
-- @treturn bool
---
function MusicPlayerScript:IsActive()
	if IsServer() then
		return self.active
	else
		return self:GetEntity().active
	end
end

---
-- Get the next song to play.
--
-- @tparam  ?number  Song.
---
function MusicPlayerScript:GetNextSong()
	local currentQueuePosition = self:GetCurrentQueuePosition()

	if nil == currentQueuePosition then
		return 1
	elseif (currentQueuePosition + 1) <= #self.properties[MusicPlayerScript.PROPERTY_QUEUE] then
		return currentQueuePosition + 1
	else
		return nil
	end
end

---
-- Get the previous song to play.
--
-- @tparam  ?number  Song.
---
function MusicPlayerScript:GetPreviousSong()
	local currentQueuePosition = self:GetCurrentQueuePosition()

	if nil == currentQueuePosition then
		return 1
	elseif (currentQueuePosition - 1) >= 1 then
		return currentQueuePosition - 1
	else
		return nil
	end
end


---
-- Return the SoundAsset for the given song.
--
-- @tparam  ?number  song
-- @treturn ?SoundAsset
---
function MusicPlayerScript:GetSoundAssetForSong(song)
	local soundAsset = nil
	if nil ~= song then
		soundAsset = self.properties[MusicPlayerScript.PROPERTY_QUEUE][song] or nil

		if nil == soundAsset then
			song = nil
		end
	end

	return soundAsset
end

---
-- Play the given song.
--
-- @tparam  ?number  song  Song to play.
---
function MusicPlayerScript:Play(song)
	Printf("MusicPlayer: Play {1}", song)

	local currentQueuePosition = self:GetCurrentQueuePosition()
	song = song or currentQueuePosition or self:GetNextSong()

	if song ~= currentQueuePosition and (IsServer() or not self.connected) then
		self:SetCurrentQueuePosition(song)
	end

	if IsServer() then
		self:SendToAllClients("CallIfConnected", "Play", song)
		self.active = true
	else
		local entity = self:GetEntity()
		local sound  = self:GetSoundAssetForSong(song)

		if entity.sound ~= sound then
			Printf("MusicPlayer: Setting SoundAsset to {1}", sound)
			entity.sound = sound
			self.currentSongProgress = 0
		end

		self.currentQueuePosition = song
		self:GetEntity().active = true

		self:PrintNowPlaying()
	end
end

---
-- Pause playback.
---
function MusicPlayerScript:Pause()
	if IsServer() then
		self:SendToAllClients("CallIfConnected", "Pause")
		self.active = false
	else
		self:GetEntity().active = false
		Printf("Song paused at {1}", self.currentSongProgress)
	end
end

---
-- Stop playback.
---
function MusicPlayerScript:Stop()
	Printf("MusicPlayer: Stop")

	if IsServer() or not self.connected then
		self:SetCurrentQueuePosition(nil)
	end

	if IsServer() then
		self:SendToAllClients("CallIfConnected", "Stop")
		self.active = false
	else
		local entity = self:GetEntity()
		entity.active = false
		entity.sound = null
		self.currentSongProgress = 0
	end
end

---
-- Go to the next song.
---
function MusicPlayerScript:Next()
	Printf("MusicPlayer: Next")

	local nextSong = self:GetNextSong()

	if nextSong then
		self:Play(nextSong)
	else
		self:Stop()
	end
end


---
-- Go to the next song.
---
function MusicPlayerScript:Previous()
	Printf("MusicPlayer: Previous")

	local song = self:GetPreviousSong()

	if song then
		self:Play(song)
	else
		self:Stop()
		self:Play()
	end
end


---
-- Return the name of the song that is currently playing.
---
function MusicPlayerScript:PrintNowPlaying()
	local soundAsset = self:ClientGetSound()

    local songName
	if nil == soundAsset then
		songName = "none"
	else
		songName = soundAsset:GetName()
	end

	--	self:GetEntity().MusicPlayerWidget.js.MusicPlayerModel.nowPlaying = songName

	Printf("Now Playing: {1}", songName)
end

---
-- Call eventName, but only if this MusicPlayer is connected to the shared server MusicPlayer instance.
--
-- @tparam       string        eventName
-- @tparam[opt]  {string,...}  args
---
function MusicPlayerScript:CallIfConnected(eventName, ...)
	Printf("MusicPlayer: CallIfConnected {1}, ...", eventName)

	if self.connected then
		self:SendToScript(eventName, ...)
	end
end

return MusicPlayerScript
