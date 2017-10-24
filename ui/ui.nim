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
var mpdRequestChannel: Channel[OmnimMpdRequest]
var mpdResponseChannel: Channel[OmnimMpdResponse]

type UiResultType* = enum
    UiSuccess
    UiFailure

type UiResult* = ref object
    case kind*: UiResultType
    of UiFailure: error*: string
    else: discard

proc mpdActorLoop(host: string, port: uint16, timeout: uint32) {.thread.} =
    try:
        var mpdCtl = initMpdCtl(host, port, timeout)
        defer: mpdCtl.close()
        while true:
            let request: OmnimMpdRequest = mpdRequestChannel.recv()
            case request.kind:
                of MpdSearch:
                    mpdResponseChannel.send(OmnimMpdResponse(kind: MpdSearchResults, songResults: mpdCtl.searchSongs(request.searchQuery)))
                of MpdReplaceAndPlay:
                    mpdCtl.replaceAndPlay(request.toReplaceAndPlay)
                of MpdEnqueue:
                    mpdCtl.enqueue(request.toEnqueue)
                of MpdClose:
                    return
    except:
        mpdResponseChannel.send(OmnimMpdResponse(kind: MpdErrorResponse, errorMessage: getCurrentExceptionMsg()))

proc stopUi*() =
    nb.shutdown()
    mpdRequestChannel.send(OmnimMpdRequest(kind: MpdClose))
    close mpdResponseChannel
    close mpdRequestChannel

proc runUi*(host: string, port: uint16, timeout: uint32, songMode: bool = false): UiResult =
    result = UiResult(kind: UiSuccess)
    nb = newNimbox()
    open mpdResponseChannel
    open mpdRequestChannel
    spawn mpdActorLoop(host, port, timeout)
    defer: stopUi()
    var lastTime = 0.0
    var searchBox = initSearchBox(0, 0, nb.width, 1)
    var listPane = initMpdListPane(0, 1, nb.width, nb.height-1, songMode)
    var queryChanged = false
    while true:

        nb.clear()
        listPane.drawTo(nb)
        searchBox.drawTo(nb)
        nb.present()

        let thisTime = epochTime()
        if queryChanged and lastTime + 0.1 < thisTime: # Execute search every 100ms
            lastTime = thisTime
            queryChanged = false
            let nextQuery = $searchBox.contents
            if len(nextQuery) >= MINIMUM_CHARACTERS:
                mpdRequestChannel.send(OmnimMpdRequest(kind: MpdSearch, searchQuery: nextQuery))

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
                    listPane.getCurrentValue().map(proc(value: MpdEither) = mpdRequestChannel.send(OmnimMpdRequest(
                        kind: MpdReplaceAndPlay,
                        toReplaceAndPlay: @[value]
                    )))
                elif nbEvent.ch == Rune('2') and nbEvent.mods.contains(Modifier.Ctrl):
                    listPane.getCurrentValue().map(proc(value: MpdEither) = mpdRequestChannel.send(OmnimMpdRequest(
                        kind: MpdEnqueue,
                        toEnqueue: @[value]
                    )))
                    listPane.down()
                elif nbEvent.ch == Rune('Z') and nbEvent.mods.contains(Modifier.Ctrl):
                    listPane.toggleSongMode()
                elif nbEvent.sym == Symbol.Character:
                    searchBox.handleSearchBoxInput(nbEvent.ch)
                    queryChanged = true
                elif nbEvent.sym == Symbol.Space:
                    searchBox.handleSearchBoxInput(Rune(' '))
                    queryChanged = true
                elif nbEvent.sym == Symbol.Backspace:
                    searchBox.backspace()
                    queryChanged = true
            of EventType.Resize:
                listPane.resizePane(nbEvent.w, nbEvent.h-1)
                searchBox.resizePane(nbEvent.w, 1)
            else:
                discard

        if len(searchBox.contents) < MINIMUM_CHARACTERS:
            listPane.setValues(@[])

        if mpdResponseChannel.peek() > 0:
            let response = mpdResponseChannel.recv()
            case response.kind:
                of MpdSearchResults:
                    listPane.setValues(response.songResults)
                of MpdErrorResponse:
                    return UiResult(kind: UiFailure, error: "MPD error: " & response.errorMessage)

