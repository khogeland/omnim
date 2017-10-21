import
    pane,
    sets,
    strutils,
    sequtils,
    options,
    nimbox,
    os

type ListPane* = ref object of Pane
    values*: seq[string]
    wrap*: bool # TODO actually implement
    currentViewLocation: int
    currentView: seq[string]
    cursor: int

proc updateView(this: ListPane) =
    this.currentView = this.values[this.currentViewLocation..min(this.currentViewLocation+this.height, len(this.values)-1)]

proc initListPane*(x, y, width, height: int): ListPane =
    result = ListPane(x: x, y: y, width: width, height: height, values: newSeq[string](), wrap: false)
    result.updateView()

proc getCurrentValue*(this: ListPane): Option[string] =
    return
        if this.values.len > 0:
            some(this.values[this.currentViewLocation+this.cursor])
        else:
            none(string)

proc moveViewUp(this: ListPane) =
    this.currentViewLocation = max(0, this.currentViewLocation-1)
    this.updateView()

proc moveViewDown(this: ListPane) =
    this.currentViewLocation =
        if this.currentViewLocation == len(this.values)-this.height: # at the bottom
            this.currentViewLocation
        else:
            this.currentViewLocation+1
    this.updateView()

proc up*(this: ListPane) =
    let hitTop = this.cursor == 0
    if hitTop:
        this.moveViewUp()
    else:
        this.cursor -= 1

proc down*(this: ListPane) =
    if this.cursor == len(this.values)-1:
        return
    let hitBottom = this.cursor == this.height-1
    if hitBottom:
        this.moveViewDown()
    else:
        this.cursor += 1

proc setValues*(this: ListPane, values: seq[string]) =
    this.cursor = 0
    this.currentViewLocation = 0
    this.values = values
    this.updateView()

method drawTo*(this: ListPane, nb: Nimbox) =
    for i, t in this.currentView:
        let style: Style =
            if i == this.cursor:
                styReverse
            else:
                styNone
        writeFile("fail", t)
        nb.print(this.x, this.y + i, t, clrDefault, clrDefault, style)
    #nb.print(this.x+100, this.y, $this.cursor)
    #nb.print(this.x+110, this.y, $this.currentViewLocation)
    #nb.print(this.x+100, this.y+1, $this.getCurrentValue())
