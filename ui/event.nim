import
    libmpdclient,
    nimbox,
    ../mpd/album

type OmnimSearchEventType* = enum
    UpdateQuery
    ExecuteSearch
    SearchClose

type OmnimSearchResultsEvent* = ref object
    songs*: seq[ptr mpd_song]

type OmnimSearchEvent* = ref object
    case kind*: OmnimSearchEventType
    of UpdateQuery:
        query*: string
    else: discard

