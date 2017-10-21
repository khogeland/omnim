import
    nimbox,
    options,
    os,
    unicode,
    strutils,
    locks,
    threadpool

import
    pane,
    listpane,
    searchbox

import
    ../mpd/searchstate,
    ../mpd/mpdctl,
    ../util/atomicvar

proc searchHandler(lp: ptr ListPane, searchState: ptr SearchState, query: ptr Atomic[string], uiLock: ptr Lock) {.thread.} =
    while true:
        sleep(100)
        let current = query[].getAndSet(nil)
        if current != nil:
            var results = searchState[].search(current)
            withLock uiLock[]:
                lp[].setValues(results)

proc startUi*(searchState: SearchState, mpdCtl: MpdCtl) =
    var nb = newNimbox()
    defer: nb.shutdown()

    var listPane = initListPane(
        0, 1, nb.width, nb.height
    )

    var query = initAtomic[string](nil)
    var uiLock: Lock
    uiLock.initLock()

    #TODO Is there a better way to share memory? Does this mess with GC? Also I need a "close" signal
    spawn searchHandler(unsafeAddr listPane, unsafeAddr searchState, addr query, addr uiLock)

    let searchBox = initSearchBox(
        0, 0, nb.width, 1,
        proc(s: string) =
            query.setValue(s)
    )

    nb.clear()
    while true:
        nb.clear()
        for i in 0..nb.height:
            nb.print(0, i, spaces(nb.width))
        listPane.drawTo(nb)
        searchBox.drawTo(nb)
        nb.present()
        let event = nb.peekEvent(100)
        case event.kind:
            of EventType.Key:
                withLock uiLock:
                    if (event.sym == Symbol.Down):
                        listPane.down()
                    elif (event.sym == Symbol.Up):
                        listPane.up()
                    elif event.sym == Symbol.Enter:
                        listPane.getCurrentValue().map(proc(value: string) = mpdCtl.replaceAndPlay(searchState.getResult(value)))
                    elif event.sym == Symbol.Space and event.mods.contains(Modifier.Ctrl):
                        listPane.getCurrentValue().map(proc(value: string) = mpdCtl.enqueue(searchState.getResult(value)))
                    elif event.sym == Symbol.Character:
                        searchBox.handleSearchBoxInput(event.ch)
                    elif event.sym == Symbol.Space:
                        searchBox.handleSearchBoxInput(Rune(' '))
                    elif event.sym == Symbol.Backspace:
                        searchBox.backspace()
                    elif event.sym == Symbol.Escape:
                        return
            of EventType.Resize:
                withLock uiLock:
                    listPane.resizePane(event.w, event.h)
                    searchBox.resizePane(event.w, 1)
            else:
                discard

