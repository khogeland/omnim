import
    libmpdclient,
    nimbox,
    uistate,
    ../mpd/album

type OmnimStateEventType* = enum
    NimboxEvent
    SearchResults
    StateClose

type OmnimSearchEventType* = enum
    UpdateQuery
    ExecuteSearch
    SearchClose

type OmnimDrawEventType* = enum
    UpdateState
    Redraw
    DrawClose


type OmnimStateEvent* = ref object
    case kind*: OmnimStateEventType
    of NimboxEvent:
        nimboxEvent*: Event
    of SearchResults:
        songs*: seq[ptr mpd_song]
    else: discard

type OmnimSearchEvent* = ref object
    case kind*: OmnimSearchEventType
    of UpdateQuery:
        query*: string
    else: discard

type OmnimDrawEvent* = ref object
    case kind*: OmnimDrawEventType
    of UpdateState:
        searchBoxState*: SearchBoxState
        listState*: ListState
    else: discard


