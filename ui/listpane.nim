import
    pane,
    sets,
    strutils,
    sequtils,
    options,
    nimbox,
    os

type ListPane*[T] = ref object of Pane
    values*: seq[T]
    wrap*: bool # TODO actually implement
    currentViewLocation: int
    currentView: seq[string]
    cursor: int

proc updateView[T](this: ListPane[T]) =
    this.currentView = this.values[this.currentViewLocation..min(this.currentViewLocation+this.height, len(this.values)-1)].map(proc(t: T): string = $t)

method resizePane*[T](this: ListPane[T], width, height: uint)  =
    procCall Pane(this).resizePane(width, height)
    this.updateView()

proc initListPane*[T](x, y, width, height: int): ListPane[T] =
    result = ListPane[T](x: x, y: y, width: width, height: height, values: newSeq[T](), wrap: false)
    result.updateView()

proc getCurrentValue*[T](this: ListPane[T]): Option[T] =
    return
        if this.values.len > 0:
            some(this.values[this.currentViewLocation+this.cursor])
        else:
            none(T)

proc moveViewUp[T](this: ListPane[T]) =
    this.currentViewLocation = max(0, this.currentViewLocation-1)
    this.updateView()

proc moveViewDown[T](this: ListPane[T]) =
    this.currentViewLocation =
        if this.currentViewLocation == len(this.values)-this.height: # at the bottom
            this.currentViewLocation
        else:
            this.currentViewLocation+1
    this.updateView()

proc up*[T](this: ListPane[T]) =
    let hitTop = this.cursor == 0
    if hitTop:
        this.moveViewUp()
    else:
        this.cursor -= 1

proc down*[T](this: ListPane[T]) =
    if this.cursor == len(this.values)-1:
        return
    let hitBottom = this.cursor == this.height-1
    if hitBottom:
        this.moveViewDown()
    else:
        this.cursor += 1

proc setValues*[T](this: ListPane[T], values: seq[T]) =
    this.cursor = 0
    this.currentViewLocation = 0
    this.values = values
    this.updateView()

method drawTo*[T](this: ListPane[T], nb: Nimbox) =
    for i, t in this.currentView:
        let style: Style =
            if i == this.cursor:
                styReverse
            else:
                styNone
        nb.print(this.x, this.y + i, t, clrDefault, clrDefault, style)
    #nb.print(this.x+100, this.y, $this.cursor)
    #nb.print(this.x+110, this.y, $this.currentViewLocation)
    #nb.print(this.x+100, this.y+1, $this.getCurrentValue())
