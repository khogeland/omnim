import
    nimbox,
    options,
    os,
    unicode,
    strutils,
    locks,
    threadpool,
    sharedstrings,
    times,
    sharedlist,
    libmpdclient

import
    event,
    uistate,
    pane,
    listpane,
    searchbox

import
    ../mpd/mpdctl,
    ../mpd/album,
    ../mpd/songutils,
    ../mpd/mpdeither,
    ../util/atomicvar

const MINIMUM_CHARACTERS = 3

var nb: Nimbox
var drawChannel: Channel[OmnimDrawEvent]
var searchChannel: Channel[OmnimSearchEvent]
var stateChannel: Channel[OmnimStateEvent]

proc drawLoop() {.thread.} = 
    var searchBoxState = initSearchBoxState()
    var listState = initListState()
    while true:
        let event: OmnimDrawEvent = drawChannel.recv()
        case event.kind:
            of UpdateState:
                if event.searchBoxState != nil:
                    searchBoxState = event.searchBoxState
                if event.listState != nil:
                    listState = event.listState
            of Redraw:
                nb.clear()
                searchBoxState.drawTo(nb, 0, 0)
                listState.drawTo(nb, 0, 1)
                nb.present()
            of DrawClose:
                return

proc searchLoop(myCtl: MpdCtl) {.thread.} =
    var nextQuery = ""
    while true:
        let event: OmnimSearchEvent = searchChannel.recv()
        case event.kind:
            of UpdateQuery:
                nextQuery = event.query
            of ExecuteSearch:
                if len(nextQuery) >= MINIMUM_CHARACTERS:
                    let query = nextQuery
                    nextQuery = ""
                    stateChannel.send(OmnimStateEvent(kind: SearchResults, songs: myCtl.searchSongs(query)))
            of SearchClose:
                return

proc stateLoop(myCtl: MpdCtl, songMode: bool) {.thread.} =
    var searchBox = initSearchBox(0, 0, nb.width, 1)
    var listPane = initMpdListPane(0, 1, nb.width, nb.height-1, songMode)
    while true:
        let event: OmnimStateEvent = stateChannel.recv()
        var drawThreadUpdate = OmnimDrawEvent(kind: UpdateState)
        var searchThreadUpdate = OmnimSearchEvent(kind: UpdateQuery)

        proc updateSearchBoxState() =
            drawThreadUpdate.searchBoxState = SearchBoxState(query: searchBox.contents)
            searchThreadUpdate.query = $searchBox.contents

        proc updateListState() =
            drawThreadUpdate.listState = ListState(currentView: listPane.currentView, cursor: listPane.cursor)

        case event.kind:
            of NimboxEvent:
                let nbEvent = event.nimboxEvent
                case nbEvent.kind:
                    of EventType.Key:
                        if (nbEvent.sym == Symbol.Down):
                            listPane.down()
                            updateListState()
                        elif (nbEvent.sym == Symbol.Up):
                            listPane.up()
                            updateListState()
                        elif nbEvent.sym == Symbol.Enter:
                            listPane.getCurrentValue().map(proc(value: MpdEither) = myCtl.replaceAndPlay(value))
                        elif nbEvent.ch == Rune('2') and nbEvent.mods.contains(Modifier.Ctrl):
                            listPane.getCurrentValue().map(proc(value: MpdEither) = myCtl.enqueue(value))
                            listPane.down()
                            updateListState()
                        elif nbEvent.ch == Rune('Z') and nbEvent.mods.contains(Modifier.Ctrl):
                            listPane.toggleSongMode()
                            updateListState()
                        elif nbEvent.sym == Symbol.Character:
                            searchBox.handleSearchBoxInput(nbEvent.ch)
                            updateSearchBoxState()
                        elif nbEvent.sym == Symbol.Space:
                            searchBox.handleSearchBoxInput(Rune(' '))
                            updateSearchBoxState()
                        elif nbEvent.sym == Symbol.Backspace:
                            searchBox.backspace()
                            updateSearchBoxState()
                    of EventType.Resize:
                        listPane.resizePane(nbEvent.w, nbEvent.h-1)
                        searchBox.resizePane(nbEvent.w, 1)
                        updateListState()
                        updateSearchBoxState()
                    else:
                        discard
            of SearchResults:
                listPane.setValues(event.songs)
                updateListState()
            of StateClose:
                return

        if drawThreadUpdate.listState != nil or drawThreadUpdate.searchBoxState != nil:
            drawChannel.send(drawThreadUpdate)

        if searchThreadUpdate.query != nil:
            searchChannel.send(searchThreadUpdate)

proc stopUi*() =
    nb.shutdown()
    drawChannel.send(OmnimDrawEvent(kind: DrawClose))
    searchChannel.send(OmnimSearchEvent(kind: SearchClose))
    stateChannel.send(OmnimStateEvent(kind: StateClose))
    close drawChannel
    close searchChannel
    close stateChannel

proc startUi*(mpd: MpdCtl, songMode: bool = false) =
    nb = newNimbox()
    open drawChannel
    open searchChannel
    open stateChannel
    spawn drawLoop()
    spawn searchLoop(mpd)
    spawn stateLoop(mpd, songMode)
    var lastTime = 0.0
    while true:
        let thisTime = epochTime()
        drawChannel.send(OmnimDrawEvent(kind: Redraw))
        if lastTime + 0.5 < thisTime: # Execute search every half-second
            lastTime = thisTime
            searchChannel.send(OmnimSearchEvent(kind: ExecuteSearch))
        let event = nb.peekEvent(10)
        case event.kind:
            of EventType.Key:
                if event.sym == Symbol.Escape:
                    stopUi()
                    return
            else: discard
        stateChannel.send(OmnimStateEvent(kind: NimboxEvent, nimboxEvent: event))

