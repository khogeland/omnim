import
    strutils,
    sequtils,
    unicode

import
    pane

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
    this.contents &= input

proc initSearchBox*(x, y, w, h: int): SearchBox =
    return SearchBox(x: x, y: y, width: w, height: h, contents: @[])

proc drawTo*(this: SearchBox, nb: Nimbox) =
    let querySpace = this.width - PREFIX_LEN - 1
    let visibleLine =
        if querySpace > 0: this.contents[max(0, len(this.contents) - querySpace)..^1]
        else: @[]
    let line = PREFIX & $visibleLine
    let lineLen = len(visibleLine) + PREFIX_LEN
    var afterCursor = spaces(max(nb.width-lineLen-1, 0))
    nb.print(this.x, this.y, line, clrDefault, clrDefault, styUnderline)
    nb.print(this.x + lineLen, this.y, " ", clrDefault, clrDefault, styReverse)
    nb.print(this.x + lineLen + 1, this.y, afterCursor, clrDefault, clrDefault, styUnderline)

