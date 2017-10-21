import
    nimbox,
    options,
    os,
    unicode,
    strutils,
    threadpool

import
    listpane,
    searchbox

import
    ../searchstate,
    ../mpd/mpdctl,
    ../util/atomicvar

proc searchHandler(lp: ptr ListPane, searchState: ptr SearchState, query: ptr Atomic[string]) {.thread.} =
    while true:
        sleep(100)
        let current = query[].getAndSet(nil)
        if current != nil:
            lp[].setValues(searchState[].search(current))

proc startUi*(searchState: SearchState, mpdCtl: MpdCtl) =
    var nb = newNimbox()
    defer: nb.shutdown()

    var listPane = initListPane(
        0, 1, nb.width, nb.height
    )

    var query = initAtomic[string](nil)

    spawn searchHandler(unsafeAddr listPane, unsafeAddr searchState, addr query)

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
            else:
                discard

