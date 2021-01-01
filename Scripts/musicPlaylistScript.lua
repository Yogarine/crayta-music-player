--------------------------------------------------------------------------------------------------------
-- @module    Yogarine.MusicPlayer
-- @author    Alwin "Yogarine" Garside <alwin@garsi.de>
-- @copyright 2020 Alwin Garside
-- @license   https://opensource.org/licenses/BSD-2-Clause 2-Clause BSD License
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
-- @type MusicPlaylistScript
--------------------------------------------------------------------------------------------------------

---
-- @field properties Properties: Holds the values that have been set on an instance of a script.
---
local MusicPlaylistScript = {
    PROPERTY_TRACKS = "tracks",
}

---
-- Script properties are defined here
---
MusicPlaylistScript.Properties = {
    {
        name      = MusicPlaylistScript.PROPERTY_TRACKS,
        type      = "soundasset",
        tooltip   = "Songs to play.",
        container = "array",
    },
}

---
-- This function is called on the server when this entity is created
---
function MusicPlaylistScript:Init()
end

return MusicPlaylistScript
