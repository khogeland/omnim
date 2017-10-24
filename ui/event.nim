import
    libmpdclient,
    nimbox,
    ../mpd/mpdeither

type OmnimMpdRequestType* = enum
    MpdReplaceAndPlay
    MpdEnqueue
    MpdSearch
    MpdClose

type OmnimMpdResponseType* = enum
    MpdSearchResults
    MpdErrorResponse

type OmnimMpdRequest* = ref object
    case kind*: OmnimMpdRequestType
    of MpdReplaceAndPlay:
        toReplaceAndPlay*: seq[MpdEither]
    of MpdEnqueue:
        toEnqueue*: seq[MpdEither]
    of MpdSearch:
        searchQuery*: string
    else: discard

type OmnimMpdResponse* = ref object
    case kind*: OmnimMpdResponseType
    of MpdSearchResults:
        songResults*: seq[ptr mpd_song]
    of MpdErrorResponse:
        errorMessage*: string

