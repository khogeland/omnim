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
    if len(this.contents) + PREFIX_LEN < this.width-1:
        this.contents &= input

proc initSearchBox*(x, y, w, h: int): SearchBox =
    return SearchBox(x: x, y: y, width: w, height: h, contents: @[])

proc drawTo*(this: SearchBox, nb: Nimbox) =
    let line = PREFIX & $this.contents
    let lineLen = len(this.contents) + PREFIX_LEN
    var afterCursor = spaces(nb.width-lineLen-1)
    nb.print(this.x, this.y, line, clrDefault, clrDefault, styUnderline)
    nb.print(this.x + lineLen, this.y, " ", clrDefault, clrDefault, styReverse)
    nb.print(this.x + lineLen + 1, this.y, afterCursor, clrDefault, clrDefault, styUnderline)

