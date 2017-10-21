import 
    nimbox

type Pane* = ref object of RootObj
    x*, y*, width*, height*: int

method movePane*(this: Pane, x, y: int) {.base.} =
    this.x = x
    this.y = y

method resizePane*(this: Pane, width, height: int) {.base.} =
    this.width = width
    this.height = height

method handleInput*(this: Pane, event: Event): bool {.base.} = discard

method drawTo*(this: Pane, nb: Nimbox) {.base.} = discard
