--------------------------------------------------------------------------------------------------------
--- Music Player for Crayta's editor.
---
--- To use, just drag the `Music Player` template into your World Tree, and make sure the `simulate`
--- property is enabled.
---
--- There are two ways to queue songs. By default songs are played from the currently selected Playlist
--- in the `Playlist` property. Create your own playlists by adding instances of the `Music Playlist`
--- template to the World and adding songs to the `Tracks` property.
---
--- You can also queue up additional songs in the `Queue` Property. Music Player will then play through
--- the Queue first, before returning playback to the Playlist.
---
--- Enable the PLAY property to start playback. The + and - buttons next to `PREV | NEXT` can be used to
--- skip and go back through the queue and/or playlist.
---
--- If you run into any bugs, make sure to report them here:
--- https://github.com/Yogarine/crayta-music-player/issues
---
--- @author    Alwin "Yogarine" Garside <alwin@garsi.de>
--- @copyright 2021 Alwin Garside
--- @license   https://opensource.org/licenses/MIT MIT License
---
--- @class MusicPlayer : Sound
--- @field musicPlayerScript MusicPlayerScript
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
--- @class MusicPlayerScript : Script<MusicPlayer>
--- @field properties   MusicPlayerScriptProperties @Bag of values produced from Script.Properties.
--- @field Util         Script<Sound>               @Yogarine's Util class.
--- @field connected    boolean                     @Sets whether this Player is synced with the server.
--- @field songProgress number                      @Current song's play time.
--- @field active       boolean                     @Manually keep track of active state, because we
---                                                 don't want to override the client active state by
---                                                 toggling the Entity's active property on the server.
--- @field sound        SoundAsset                  @Manually keep track of the current sound, because
---                                                 we don't want to override the client sound by
---                                                 toggling the Entity's sound property on the server.
--- @field offset       number
--- @field clientReady  boolean
--------------------------------------------------------------------------------------------------------
local MusicPlayerScript = {
	PREV_NEXT = "PREV | NEXT"
}

--------------------------------------------------------------------------------------------------------
--- @class MusicPlayerScriptProperties : Properties
--- @field PLAY              boolean
--- @field ["PREV | NEXT"]   number
--- @field Queue             PropertyArray<SoundAsset>
--- @field Playlist          MusicPlaylist
--- @field Duration          number
--- @field queuePosition     number
--- @field playlistPosition  number
--- @field songDuration      number
--------------------------------------------------------------------------------------------------------

----
--- Script properties are defined here.
----
MusicPlayerScript.Properties = {
	{
		name    = "PLAY",
		type    = "boolean",
		tooltip = "Play / Stop music playback",
	},
	{
		name    = MusicPlayerScript.PREV_NEXT,
		type    = "number",
		tooltip = "Skip to the next / previous song by pressing the +/- buttons",
		default = 0
	},
	{
		name      = "Queue",
		type      = "soundasset",
		tooltip   = "Songs to play.",
		container = "array"
	},
	{
		name    = "Playlist",
		type    = "entity",
		tooltip = "Active Playlist.",
		is      = "Locator"
	},
	{
		name    = "Duration",
		type    = "number",
		tooltip = "Default song duration",
		default = 210,
		editor  = "seconds"
	},
	{
		name               = "queuePosition",
		type               = "number",
		allowFloatingPoint = false,
		editable           = false,
		default            = 0
	},
	{
		name               = "playlistPosition",
		type               = "number",
		allowFloatingPoint = false,
		editable           = false,
		default            = 0
	},
	{
		name     = "songDuration",
		type     = "number",
		editable = false,
		default  = 1500
	},
}

----
--- Initializes all the fields on this instance.
---
--- @return void
----
function MusicPlayerScript:InitFields()
	--Printf("MusicPlayer: InitFields")

	local entity = self:GetEntity()

	self.Util = entity.util
	self.active = entity.active
	self.offset = self.properties[MusicPlayerScript.PREV_NEXT]
	self.songProgress = 0
end

----
--- This function is called on the server when this entity is created.
---
--- @return void
----
function MusicPlayerScript:Init()
	--Printf("MusicPlayer: Init")

	self:InitFields()

	self.clientReady = false
end

----
--- This function is called on the client when this entity is created
---
--- @return void
----
function MusicPlayerScript:ClientInit()
	--Printf("MusicPlayer: ClientInit")

	self:InitFields()
	self.connected = true

	self.localProperties = {
		----
        --- @type MusicPlaylist
        ----
		Playlist         = self.properties.Playlist,

		----
        --- @type PropertyArray<SoundAsset>
        ----
		Queue            = self.properties.Queue,

		----
        --- @type number
        ----
		Duration         = self.properties.Duration,

		----
        --- @type boolean
        ----
		PLAY             = self.properties.PLAY,

		----
        --- Current position in queue.
        ---
        --- @type number
        ----
		queuePosition    = self.properties.queuePosition,

		----
        ---Current position in playlist.
        ---
        --- @type number
        ----
		playlistPosition = self.properties.playlistPosition,

		----
        --- @type number
        ----
		songDuration     = self.properties.songDuration
			or self.properties.Duration,
	}

	self:SendToServer("OnClientReady")
end

function MusicPlayerScript:OnClientReady()
	self.clientReady = true
end

---
--- Called each frame on the server.
---
--- @param  deltaTimeSeconds  number  @Time elapsed since the last frame was rendered.
--- @return void
---
function MusicPlayerScript:OnTick(deltaTimeSeconds)
	if not self.clientReady then
		return
	end

	-- Check if play state has changed.
	local play = self.properties.PLAY
	if self.active ~= play then
		--Printf("MusicPlayer: self.active ({1}) != self.properties.PLAY ({2})", self.active, play)

		--self.active = play
		if play then
			self:Play()
		else
			self:Stop()
		end
	end

	if self.offset ~= self.properties[MusicPlayerScript.PREV_NEXT] then
		--Printf(
		--	"MusicPlayer: offset ({1}) ~= Prev / Next ({2})",
		--	self.offset, self.properties[MusicPlayerScript.PREV_NEXT]
		--)

		if self.properties[MusicPlayerScript.PREV_NEXT] > self.offset then
			self:Next()
		else
			self:Previous()
		end

		self.offset = self.properties[MusicPlayerScript.PREV_NEXT]
	end

	if self.active then
		self.songProgress = self.songProgress + deltaTimeSeconds
	end

	if self.songProgress >= self.properties.songDuration then
		--Printf(
		--	"MusicPlayer: songProgress ({1}) > properties.songDuration ({2})",
		--	self.songProgress, self.properties.songDuration
		--)

		self:Next()
	end
end

---
--- Called each frame on the client.
---
--- @param  deltaTimeSeconds  number  @Time elapsed since the last frame was rendered.
--- @return void
---
function MusicPlayerScript:ClientOnTick(deltaTimeSeconds)
	if self:GetEntity().active then
		self.songProgress = self.songProgress + deltaTimeSeconds
	end

	if not self.connected then
		-- Check if play state has changed.
		local play = self.localProperties.PLAY
		if self.active ~= play then
			--Printf("MusicPlayer: self.active ({1}) != self.properties.PLAY ({2})", self.active, play)

			--self.active = play
			if play then
				self:Play()
			else
				self:Stop()
			end
		end

		if self.songProgress >= self.localProperties.songDuration then
			--Printf(
			--	"MusicPlayer: self.connected " ..
			--		"and self.songProgress ({1}) >= self.localProperties.songDuration ({2})",
			--	self.songProgress, self.localProperties.songDuration
			--)

			self:Next()
		end
	end
end

----
--- @return PropertyArray<SoundAsset>
----
function MusicPlayerScript:GetPlaylist()
	--Print("MusicPlayer: GetPlaylist")

	local playlist = (IsServer() or self.connected)
		and self.properties.Playlist
		or self.localProperties.Playlist

	return playlist.musicPlaylistScript.properties.tracks
end

----
--- @param  position  number
--- @return SoundAsset
----
function MusicPlayerScript:GetPlaylistAsset(position)
	--Printf("MusicPlayer: GetPlaylistAsset {1}", position)

	if 0 == position then
		return nil
	end

	local playlist = (IsServer() or self.connected)
		and self.properties.Playlist
		or self.localProperties.Playlist

	return playlist.musicPlaylistScript.properties.tracks[position] or nil
end

----
--- @return boolean
----
function MusicPlayerScript:GetPlay()
	--Print("MusicPlayer: GetPlay")

	return (IsServer() or self.connected)
		and self.properties.PLAY
		or self.localProperties.PLAY
end

--
-- @param  play  boolean
-- @return void
--
--function MusicPlayerScript:SetPlay(play)
--	Printf("MusicPlayer: SetPlay {1}", play)
--
--	if IsServer() then
--		self.properties.PLAY = play
--	elseif self.connected then
--		if play ~= self.properties.PLAY then
--			self:SendToServer("SetPlay", play)
--		end
--	else
--		self.localProperties.PLAY = play
--	end
--end

----
--- Get the current song.
---
--- @return number
----
function MusicPlayerScript:GetPlaylistPosition()
	--Print("MusicPlayer: GetPlaylistPosition")

	return (IsServer() or self.connected)
		and self.properties.playlistPosition
		or self.localProperties.playlistPosition
end

----
--- Set the current song.
---
--- @todo Figure out way to declare song Durations in playlists.
---
--- @param position number|nil
----
function MusicPlayerScript:SetPlaylistPosition(position)
	--Printf("MusicPlayer: SetPlaylistPosition {1}", position)

	position = nil == position and 0 or position

	if IsServer() then
		if self.properties.playlistPosition ~= position then
			self.properties.playlistPosition = position
		end
	elseif self.connected then
		if self.properties.playlistPosition ~= position then
			self:SendToServer("SetPlaylistPosition", position)
		end
	else
		if self.localProperties.playlistPosition ~= position then
			self.localProperties.playlistPosition = position
		end
	end
end

----
--- @return PropertyArray<SoundAsset>
----
function MusicPlayerScript:GetQueue()
	--Print("MusicPlayer: GetQueue")

	return (IsServer() or self.connected)
		and self.properties.Queue
		or self.localProperties.Queue
end

----
--- @param  position  number
--- @return SoundAsset
----
function MusicPlayerScript:GetQueueAsset(position)
	--Printf("MusicPlayer: GetQueueAsset {1}", position)

	if 0 == position then
		return nil
	end

	return (IsServer() or self.connected)
		and self.properties.Queue[position]
		or self.localProperties.Queue[position]
end

----
--- Get the current song.
---
--- @return number
----
function MusicPlayerScript:GetQueuePosition()
	--Print("MusicPlayer: GetQueuePosition")

	return (IsServer() or self.connected)
		and self.properties.queuePosition
		or self.localProperties.queuePosition
end

----
--- Set the current song.
---
--- @todo Figure out way to declare song Durations in playlists.
---
--- @param song number|nil
----
function MusicPlayerScript:SetQueuePosition(song)
	--Printf("MusicPlayer: SetQueuePosition {1}", song)

	song = nil == song and 0 or song

	if IsServer() then
		if self.properties.queuePosition ~= song then
			self.properties.queuePosition = song
			self.properties.songDuration = self.properties.Duration
		end
	elseif self.connected then
		if self.properties.queuePosition ~= song then
			self:SendToServer("SetQueuePosition", song)
		end
	else
		if self.localProperties.queuePosition ~= song then
			self.localProperties.queuePosition = song
			self.localProperties.songDuration = self.properties.Duration
		end
	end

	self.songProgress = 0
end

----
--- @return SoundAsset
----
function MusicPlayerScript:GetSound()
	local result = IsServer() and self.sound or self:GetEntity().sound

	--Printf("MusicPlayer: GetSound: {1}", result)

	return result
end

----
--- @param  sound  SoundAsset
--- @return void
----
function MusicPlayerScript:SetSound(sound)
	--Printf("MusicPlayer: SetSound {1}", sound and sound:GetName() or "nil")

	if IsServer() then
		self.sound = sound
		self.songProgress = 0
		self.properties.songDuration = self.properties.Duration
		self:SendToAllClients("CallIfConnected", "ClientSetSound", sound)
	elseif self.connected then
		self:SendToServer("SetSound", sound)
	else
		self:ClientSetSound(sound)
	end
end

----
--- @param  sound  SoundAsset
--- @return void
----
function MusicPlayerScript:ClientSetSound(sound)
	--Printf("MusicPlayer: ClientSetSound {1}", sound and sound:GetName() or "nil")

	assert(IsClient(), "MusicPlayer: ClientSetSound() should only be called from the Client.")

	self:GetEntity().sound = sound
	self.songProgress = 0
	self.localProperties.songDuration = self.properties.Duration
end

----
--- @return boolean
----
function MusicPlayerScript:IsActive()
	local result = IsServer() and self.active or self:GetEntity().active

	--Printf("MusicPlayer: IsActive: {1}", result)

	return result
end

----
--- @param  active  boolean
--- @return void
----
function MusicPlayerScript:SetActive(active)
	--Printf("MusicPlayer: SetActive {1}", active)

	if IsServer() then
		if self.active ~= active then
			--Printf("MusicPlayer: self.active ({1}) ~= active ({2})", self.active, active)
			self.active = active
			self:SendToAllClients("CallIfConnected", "ClientSetActive", active)
		end
	elseif self.connected then
		self:SendToServer("SetSound", active)
	else
		self:ClientSetActive(active)
	end
end

----
--- @param  active  boolean
--- @return void
---
function MusicPlayerScript:ClientSetActive(active)
	--Printf("MusicPlayer: ClientSetActive {1}", active)

	assert(IsClient(), "MusicPlayer: ClientSetActive() should only be called from the Client.")

	local entity = self:GetEntity()
	if entity.active ~= active then
		entity.active = active
	end
end

----
--- @param  queuePosition  number
--- @return SoundAsset
----
function MusicPlayerScript:SelectQueuePosition(queuePosition)
	--Printf("MusicPlayer: SelectQueuePosition {1}", queuePosition)

	local musicAsset = 0 ~= queuePosition
		and self:GetQueueAsset(queuePosition)
		or nil

	--if musicAsset then
	self:SetQueuePosition(queuePosition)
	self:SetPlaylistPosition(0)
	self:SetSound(musicAsset)
	--end

	return musicAsset
end

----
--- @param  playlistPosition  number
--- @return void
----
function MusicPlayerScript:SelectPlaylistPosition(playlistPosition)
	--Printf("MusicPlayer: SelectPlaylistPosition {1}", playlistPosition)

	self:SetPlaylistPosition(playlistPosition)
	self:SetQueuePosition(0)
	self:SetSound(self:GetPlaylistAsset(playlistPosition))
end

----
--- Play the given song.
---
--- @overload fun(): void
--- @return void
----
function MusicPlayerScript:Play()
	--Printf("MusicPlayer: Play")

	if not self:GetSound() then
		self:Next()
	end

	self:SetActive(true)
	--self:SetPlay(true)

	self:PrintNowPlaying()
end

----
--- Pause playback.
---
--- @return void
----
function MusicPlayerScript:Pause()
	--Printf("MusicPlayer: Pause")

	self:SetActive(false)

	Printf("Song paused at {1}", self.songProgress)
end

----
--- Stop playback.
---
--- @return void
----
function MusicPlayerScript:Stop()
	--Printf("MusicPlayer: Stop")

	self:SetSound(nil)
	self:SetActive(false)
	--self:SetPlay(false)
end

----
--- Go to the next song.
---
--- @return void
----
function MusicPlayerScript:Next()
	--Printf("MusicPlayer: Next")

	local nextQueuePosition = self:GetQueuePosition() + 1
	if nextQueuePosition <= #self:GetQueue() then
		self:SelectQueuePosition(nextQueuePosition)
	else
		local nextPlaylistPosition = self:GetPlaylistPosition() + 1
		if nextPlaylistPosition <= #self:GetPlaylist() then
			self:SelectPlaylistPosition(nextPlaylistPosition)
		else
			-- We are at the end of the playlist. Reset positions and stop playing.
			self:SelectPlaylistPosition(0)
			--self:SetQueuePosition(0)
			--self:SetPlaylistPosition(0)
			--self:Stop()
		end
	end

	self:PrintNowPlaying()
end

----
--- Go to the next song.
---
--- @return void
----
function MusicPlayerScript:Previous()
	--Printf("MusicPlayer: Previous")

	local previousPlaylistPosition = self:GetPlaylistPosition() - 1
	if previousPlaylistPosition > 0 then
		self:SelectPlaylistPosition(previousPlaylistPosition)
	else
		local previousQueuePosition = self:GetQueuePosition() - 1
		if previousQueuePosition >= 0 then
			self:SelectQueuePosition(previousQueuePosition)
		else
			-- We're at the start of the queue. Restart playback from the beginning.
			self:Stop()
			self:Play()
		end
	end

	self:PrintNowPlaying()
end

----
--- Return the name of the song that is currently playing.
---
--- @return void
----
function MusicPlayerScript:PrintNowPlaying()
	--Printf("MusicPlayer: PrintNowPlaying")

	local soundAsset = self:GetSound()

	--- @type string
	local songName = nil == soundAsset and "none" or soundAsset:GetName()

	Printf("Now Playing: {1}", songName)
end

----
--- Call eventName, but only if this MusicPlayer is connected to the shared server MusicPlayer instance.
---
--- @param  eventName  "ClientSetSound"|"Play"|"Pause"|"Stop"
--- @vararg any
--- @return void
----
function MusicPlayerScript:CallIfConnected(eventName, ...)
	--Printf("MusicPlayer: CallIfConnected {1}, ...", eventName)

	assert(IsClient(), "CallIfConnected() should only be called on the Client.")

	if self.connected then
		--self[eventName](self, ...)
		self:SendToScript(eventName, ...)
	end
end

return MusicPlayerScript
