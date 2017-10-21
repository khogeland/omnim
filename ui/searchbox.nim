import
    strutils,
    sequtils,
    unicode

import
    pane

import
    nimbox

const MINIMUM_CHARACTERS = 2

type SearchBox* = ref object of Pane
    onInput: proc(s: string)
    contents: seq[Rune]

proc updateSearchBox(this: SearchBox) =
    if len(this.contents) >= MINIMUM_CHARACTERS:
        this.onInput($this.contents)

proc backspace*(this: SearchBox) =
    let le = len(this.contents)
    if le > 0:
        this.contents.delete(le-1, le-1)
    this.updateSearchBox()

proc handleSearchBoxInput*(this: SearchBox, input: Rune) =
    this.contents &= input
    this.updateSearchBox()

proc initSearchBox*(x, y, w, h: int, onInput: proc(s: string)): SearchBox =
    result = SearchBox(x: x, y: y, width: w, height: h, onInput: onInput, contents: @[])
    result.updateSearchBox()

method drawTo*(this: SearchBox, nb: Nimbox) =
    let linePrefix = "Search: "
    let line = linePrefix & $this.contents
    let lineLen = len(this.contents) + len(linePrefix)
    var afterCursor = spaces(nb.width-lineLen-1)
    nb.print(this.x, this.y, line, clrDefault, clrDefault, styUnderline)
    nb.print(this.x + lineLen, this.y, " ", clrDefault, clrDefault, styReverse)
    nb.print(this.x + lineLen + 1, this.y, afterCursor, clrDefault, clrDefault, styUnderline)

