--------------------------------------------------------------------------------------------------------
--- @author    Alwin "Yogarine" Garside <alwin@garsi.de>
--- @copyright 2021 Alwin Garside
--- @license   https://opensource.org/licenses/MIT MIT License
---
--- @class MusicPlaylist : Locator
--- @field musicPlaylistScript MusicPlaylistScript
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
--- @class MusicPlaylistScript : Script<MusicPlaylist>
--- @field properties MusicPlaylistScriptProperties
--------------------------------------------------------------------------------------------------------
local MusicPlaylistScript = {}

--------------------------------------------------------------------------------------------------------
--- @class MusicPlaylistScriptProperties : Properties
--- @field tracks PropertyArray<SoundAsset>
--------------------------------------------------------------------------------------------------------

----
--- Script properties are defined here.
----
MusicPlaylistScript.Properties = {
	{
		name      = "tracks",
		type      = "soundasset",
		tooltip   = "Songs to play.",
		container = "array",
	},
}

----
--- This function is called on the server when this entity is created
----
function MusicPlaylistScript:Init()
end

return MusicPlaylistScript
