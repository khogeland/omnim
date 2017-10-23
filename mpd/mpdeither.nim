import
    album,
    songutils,
    libmpdclient

type MpdType* = enum
    Song
    Album

type MpdEither* = ref object
    case kind*: MpdType
    of Song: song*: ptr mpd_song
    of Album: album*: mpd_album

proc initSongEither*(song: ptr mpd_song): MpdEither =
    return MpdEither(kind: Song, song: song)

proc initAlbumEither*(album: mpd_album): MpdEither =
    return MpdEither(kind: Album, album: album)

proc `$`*(either: MpdEither): string =
    case either.kind:
        of Song: return $either.song
        of Album: return $either.album
