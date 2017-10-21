import
    libmpdclient

proc mpd_nice_name*(song: ptr mpd_song): string =
    var ret = ""
    var artist = song.mpd_song_get_tag(MPD_TAG_ARTIST, 0)
    if artist != nil:
        ret = $artist
    var title = song.mpd_song_get_tag(MPD_TAG_TITLE, 0)
    if title != nil:
        ret = ret & " - " & $title
    return ret

proc mpd_song_get_title*(song: ptr mpd_song): string =
    $song.mpd_song_get_tag(MPD_TAG_TITLE, 0)

proc mpd_song_get_artist*(song: ptr mpd_song): string =
    $song.mpd_song_get_tag(MPD_TAG_ARTIST, 0)

proc mpd_song_get_album_artist*(song: ptr mpd_song): string =
    $song.mpd_song_get_tag(MPD_TAG_ALBUM_ARTIST, 0)

proc mpd_song_get_album*(song: ptr mpd_song): string =
    $song.mpd_song_get_tag(MPD_TAG_ALBUM, 0)

proc `$`*(song: ptr mpd_song): string =
    mpd_nice_name(song)

proc `$`*(songs: seq[ptr mpd_song]): string =
    result = ""
    for song in songs:
        result.add($song & "\n")

