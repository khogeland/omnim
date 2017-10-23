import
    strutils,
    sequtils,
    unicode

import
    pane,
    uistate

import
    nimbox

const PREFIX = "Search: "
const PREFIX_LEN = len(PREFIX)

type SearchBox* = ref object of Pane
    contents*: seq[Rune]

proc backspace*(this: SearchBox) =
    let le = len(this.contents)
    if le > 0:
        this.contents.delete(le-1, le-1)

proc handleSearchBoxInput*(this: SearchBox, input: Rune) =
    if len(this.contents) + PREFIX_LEN < this.width-1:
        this.contents &= input

proc initSearchBox*(x, y, w, h: int): SearchBox =
    return SearchBox(x: x, y: y, width: w, height: h, contents: @[])

proc drawTo*(state: SearchBoxState, nb: Nimbox, x, y: int) =
    let line = PREFIX & $state.query
    let lineLen = len(state.query) + PREFIX_LEN
    var afterCursor = spaces(nb.width-lineLen-1)
    nb.print(x, y, line, clrDefault, clrDefault, styUnderline)
    nb.print(x + lineLen, y, " ", clrDefault, clrDefault, styReverse)
    nb.print(x + lineLen + 1, y, afterCursor, clrDefault, clrDefault, styUnderline)

