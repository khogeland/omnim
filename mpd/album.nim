import
    libmpdclient,
    tables

import
    songutils

type mpd_album* = object
    artist*, title*: string
    tracks*: seq[ptr mpd_song]

proc newAlbum*(artist, title: string): mpd_album =
    assert artist != nil
    assert title != nil
    return mpd_album(artist: artist, title: title,  tracks: @[])

proc `+=`*(album: var mpd_album, song: ptr mpd_song): void =
    album.tracks.add(song)

proc albums_for*(songs: seq[ptr mpd_song]): seq[mpd_album] =
    var albums: Table[(string, string), mpd_album] = initTable[(string, string), mpd_album]()
    for song in songs:
        var album_title = mpd_song_get_album(song)
        if album_title == nil:
            album_title = "none"
        var artist = mpd_song_get_album_artist(song)
        if artist == nil:
            artist = mpd_song_get_artist(song)
            if artist == nil:
                artist = "none"
        albums.mgetOrPut((artist, album_title), newAlbum(artist, album_title)) += song
    result = @[]
    for album in albums.values():
        result.add(album)

proc `$`*(album: mpd_album): string =
    result = album.artist & " - " & album.title
    if album.tracks.len == 1:
        let title = album.tracks[0].mpd_song_get_tag(MPD_TAG_TITLE, 0)
        if title != nil:
            result &= " - " & $title

proc `$`*(albums: seq[mpd_album]): string =
    result = ""
    for album in albums:
        result.add($album & "\n")

