import
    libmpdclient,
    re

import
    songutils,
    album

type MpdCtl* = ref object
    conn*: ptr mpd_connection
    host: string
    port: uint16
    timeout_ms: uint32

proc openIfNeeded(this: MpdCtl) =
    if this.conn == nil or this.conn.mpd_connection_get_error() == MPD_ERROR_CLOSED:
        var conn = mpd_connection_new(cast[cstring](this.host), cast[cuint](this.port), this.timeout_ms)
        if conn.mpd_connection_get_error() != MPD_ERROR_SUCCESS:
            raise newException(IOError, cast[string](conn.mpd_connection_get_error_message))
        else:
            this.conn = conn

proc initMpdCtl*(host: string, port: uint16, timeout_ms: uint32): MpdCtl =
    result = MpdCtl(host: host, port: port, timeout_ms: timeout_ms)
    openIfNeeded(result)

proc close*(this: MpdCtl) =
    this.conn.mpd_connection_free()

proc enqueue*(this: MpdCtl, song: ptr mpd_song) =
    this.openIfNeeded()
    discard this.conn.mpd_run_add(song.mpd_song_get_uri())

proc enqueue*(this: MpdCtl, album: mpd_album) =
    for song in album.tracks:
        this.enqueue(song)

proc replaceAndPlay*(this: MpdCtl, song: ptr mpd_song) =
    this.openIfNeeded()
    discard this.conn.mpd_run_clear()
    this.enqueue(song)
    discard this.conn.mpd_run_play()

proc replaceAndPlay*(this: MpdCtl, album: mpd_album) =
    this.openIfNeeded()
    discard this.conn.mpd_run_clear()
    this.enqueue(album)
    discard this.conn.mpd_run_play()


proc searchSongs*(this: MpdCtl, searchStrings: seq[string]): seq[ptr mpd_song] =
    this.openIfNeeded()
    discard this.conn.mpd_search_db_songs(false)
    for str in searchStrings:
        discard this.conn.mpd_search_add_any_tag_constraint(MPD_OPERATOR_DEFAULT, str)
    discard this.conn.mpd_search_commit()
    var songs: seq[ptr mpd_song] = @[]
    var next = this.conn.mpd_recv_song()
    while next != nil:
        songs.add(next)
        next = this.conn.mpd_recv_song()
    return songs

proc searchSongs*(this: MpdCtl, query: string): seq[ptr mpd_song] =
    return this.searchSongs(query.split(re"\s+"))

proc searchAlbums*(this: MpdCtl, searchStrings: seq[string]): seq[mpd_album] =
    return albums_for(this.searchSongs(searchStrings))

proc searchAlbums*(this: MpdCtl, query: string): seq[mpd_album] =
    return albums_for(this.searchSongs(query))

