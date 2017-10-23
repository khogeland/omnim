import 
    nimbox

type Pane* = ref object of RootObj
    x*, y*, width*, height*: int

method movePane*(this: Pane, x, y: int) {.base,gcsafe.} =
    this.x = x
    this.y = y

method resizePane*(this: Pane, width, height: int) {.base,gcsafe.} =
    this.width = width
    this.height = height

method resizePane*(this: Pane, width, height: uint) {.base,gcsafe.} =
    this.resizePane(int(width), int(height))

method handleInput*(this: Pane, event: Event): bool {.base,gcsafe.} = discard

