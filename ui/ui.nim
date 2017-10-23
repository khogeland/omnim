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
var resultsChannel: Channel[OmnimSearchResultsEvent]
var searchChannel: Channel[OmnimSearchEvent]

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
                    resultsChannel.send(OmnimSearchResultsEvent(songs: myCtl.searchSongs(query)))
            of SearchClose:
                return

proc stopUi*() =
    nb.shutdown()
    searchChannel.send(OmnimSearchEvent(kind: SearchClose))
    close resultsChannel
    close searchChannel

proc startUi*(mpd: MpdCtl, songMode: bool = false) =
    nb = newNimbox()
    open resultsChannel
    open searchChannel
    spawn searchLoop(mpd)
    defer: stopUi()
    var lastTime = 0.0
    var searchBox = initSearchBox(0, 0, nb.width, 1)
    var listPane = initMpdListPane(0, 1, nb.width, nb.height-1, songMode)
    while true:

        nb.clear()
        listPane.drawTo(nb)
        searchBox.drawTo(nb)
        nb.present()

        let thisTime = epochTime()
        if lastTime + 0.1 < thisTime: # Execute search every 100ms
            lastTime = thisTime
            searchChannel.send(OmnimSearchEvent(kind: ExecuteSearch))

        var searchThreadUpdate = OmnimSearchEvent(kind: UpdateQuery)

        proc updateSearchMessage() = searchThreadUpdate.query = $searchBox.contents

        let nbEvent = nb.peekEvent(10)
        case nbEvent.kind:
            of EventType.Key:
                if nbEvent.sym == Symbol.Escape:
                    return
                if (nbEvent.sym == Symbol.Down):
                    listPane.down()
                elif (nbEvent.sym == Symbol.Up):
                    listPane.up()
                elif nbEvent.sym == Symbol.Enter:
                    listPane.getCurrentValue().map(proc(value: MpdEither) = mpd.replaceAndPlay(value))
                elif nbEvent.ch == Rune('2') and nbEvent.mods.contains(Modifier.Ctrl):
                    listPane.getCurrentValue().map(proc(value: MpdEither) = mpd.enqueue(value))
                    listPane.down()
                elif nbEvent.ch == Rune('Z') and nbEvent.mods.contains(Modifier.Ctrl):
                    listPane.toggleSongMode()
                elif nbEvent.sym == Symbol.Character:
                    searchBox.handleSearchBoxInput(nbEvent.ch)
                    updateSearchMessage()
                elif nbEvent.sym == Symbol.Space:
                    searchBox.handleSearchBoxInput(Rune(' '))
                    updateSearchMessage()
                elif nbEvent.sym == Symbol.Backspace:
                    searchBox.backspace()
                    updateSearchMessage()
            of EventType.Resize:
                listPane.resizePane(nbEvent.w, nbEvent.h-1)
                searchBox.resizePane(nbEvent.w, 1)
            else:
                discard

        if len(searchBox.contents) < MINIMUM_CHARACTERS:
            listPane.setValues(@[])

        if resultsChannel.peek() > 0:
            listPane.setValues(resultsChannel.recv().songs)

        if searchThreadUpdate.query != nil:
            searchChannel.send(searchThreadUpdate)

