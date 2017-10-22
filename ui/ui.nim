import
    nimbox,
    options,
    os,
    unicode,
    strutils,
    locks,
    threadpool,
    libmpdclient

import
    pane,
    listpane,
    searchbox

import
    ../mpd/mpdctl,
    ../mpd/album,
    ../mpd/songutils,
    ../util/atomicvar

proc searchHandler[T](lp: ptr ListPane[T], searchProc: proc(s: string): seq[T], query: ptr Atomic[string], uiLock: ptr Lock) {.thread.} =
    while true:
        sleep(100)
        let current = query[].getAndSet(nil)
        if current != nil:
            var results = searchProc(current)
            withLock uiLock[]:
                cast[ListPane[T]](lp[]).setValues(results)

proc mainLoop[T](mpdCtl: MpdCtl, nb: NimBox, listPane: ListPane[T], searchProc: proc(s: string): seq[T]) =
    var query = initAtomic[string](nil)
    var uiLock: Lock
    uiLock.initLock()

    let searchBox = initSearchBox(
        0, 0, nb.width, 1,
        proc(s: string) =
            query.setValue(s)
    )

    #TODO Is there a better way to share memory? Does this mess with GC? Also I need a "close" signal
    spawn searchHandler(unsafeAddr listPane, searchProc, addr query, addr uiLock)
    while true:
        let event = nb.peekEvent(10)
        withLock uiLock:
            nb.clear()
            listPane.drawTo(nb)
            searchBox.drawTo(nb)
            nb.present()
            case event.kind:
                of EventType.Key:
                    if (event.sym == Symbol.Down):
                        listPane.down()
                    elif (event.sym == Symbol.Up):
                        listPane.up()
                    elif event.sym == Symbol.Enter:
                        listPane.getCurrentValue().map(proc(value: T) = mpdCtl.replaceAndPlay(value))
                    elif event.sym == Symbol.Space and event.mods.contains(Modifier.Ctrl):
                        listPane.getCurrentValue().map(proc(value: T) = mpdCtl.enqueue(value))
                    elif event.sym == Symbol.Character:
                        searchBox.handleSearchBoxInput(event.ch)
                    elif event.sym == Symbol.Space:
                        searchBox.handleSearchBoxInput(Rune(' '))
                    elif event.sym == Symbol.Backspace:
                        searchBox.backspace()
                    elif event.sym == Symbol.Escape:
                        return
                of EventType.Resize:
                    listPane.resizePane(event.w, event.h)
                    searchBox.resizePane(event.w, 1)
                else:
                    discard

proc startUi*(mpdCtl: MpdCtl, songMode: bool = false ) =
    var nb = newNimbox()
    defer: nb.shutdown()

    # I couldn't get the type system to bend to my will :(
    if songMode:
        var listPane = initListPane[ptr mpd_song](0, 1, nb.width, nb.height)
        mainLoop(mpdCtl, nb, listPane, proc(s: string): seq[ptr mpd_song] = mpdCtl.searchSongs(s))
    else:
        var listPane = initListPane[mpd_album](0, 1, nb.width, nb.height)
        mainLoop(mpdCtl, nb, listPane, proc(s: string): seq[mpd_album] = mpdCtl.searchAlbums(s))


