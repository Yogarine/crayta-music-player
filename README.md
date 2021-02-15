# Crayta Music Player

Music Player for Crayta's editor. Drag the `Music Player` template into your
World Tree and make sure `simulate` is enabled. Report any bugs at
https://github.com/Yogarine/crayta-music-player/issues

## Installation

In [Crayta](https://www.crayta.com)'s Create mode, search for "Music Player" in
the community tag and install it.

## Usage

To use, just drag the `Music Player` template into your World Tree, and make
sure the `simulate` property is enabled.

There are two ways to queue songs. By default songs are played from the
currently selected Playlist in the `Playlist` property. Create your own
playlists by adding instances of the `Music Playlist` template to the World and
adding songs to the `Tracks` property.

You can also queue up additional songs in the `Queue` Property. Music Player
will then play through the Queue first, before returning playback to the
Playlist.

Enable the PLAY property to start playback. The + and - buttons next to
`PREV | NEXT` can be used to skip and go back through the queue and/or playlist.

If you run into any bugs, make sure to report them here:
https://github.com/Yogarine/crayta-music-player/issues
