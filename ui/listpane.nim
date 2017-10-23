import
    pane,
    uistate,
    ../mpd/album,
    ../mpd/mpdeither

import
    sets,
    strutils,
    sequtils,
    options,
    nimbox,
    libmpdclient,
    os

type MpdListPane* = ref object of Pane
    songMode*: bool
    values*: seq[MpdEither]
    songValues*: seq[ptr mpd_song]
    albumValues*: seq[mpd_album]
    wrap*: bool # TODO actually implement
    currentViewLocation: int
    currentView*: seq[string]
    cursor*: int

proc updateView(this: MpdListPane) =
    if this.songMode:
        this.values = this.songValues.map(proc(s: ptr mpd_song): MpdEither = initSongEither(s))
    else:
        this.values = this.albumValues.map(proc(s: mpd_album): MpdEither = initAlbumEither(s))
    this.currentView = this.values[this.currentViewLocation..min(this.currentViewLocation+this.height, len(this.values)-1)].map(proc(e: MpdEither): string = $e)

proc initMpdListPane*(x, y, width, height: int, songMode: bool): MpdListPane =
    result = MpdListPane(x: x, y: y, width: width, height: height, values: @[], songValues: @[], albumValues: @[], wrap: false, songMode: songMode)
    result.updateView()

proc toggleSongMode*(this: MpdListPane) =
    this.songMode = not this.songMode
    this.updateView()

method resizePane*(this: MpdListPane, width, height: uint) {.gcsafe.}  =
    procCall Pane(this).resizePane(width, height)
    this.updateView()

proc getCurrentValue*(this: MpdListPane): Option[MpdEither] =
    return
        if this.values.len > 0:
            some(this.values[this.currentViewLocation+this.cursor])
        else:
            none(MpdEither)

proc moveViewUp(this: MpdListPane) =
    this.currentViewLocation = max(0, this.currentViewLocation-1)
    this.updateView()

proc moveViewDown(this: MpdListPane) =
    this.currentViewLocation =
        if this.currentViewLocation == len(this.values)-this.height: # at the bottom
            this.currentViewLocation
        else:
            this.currentViewLocation+1
    this.updateView()

proc up*(this: MpdListPane) =
    let hitTop = this.cursor == 0
    if hitTop:
        this.moveViewUp()
    else:
        this.cursor -= 1

proc down*(this: MpdListPane) =
    if this.cursor == len(this.values)-1:
        return
    let hitBottom = this.cursor == this.height-1
    if hitBottom:
        this.moveViewDown()
    else:
        this.cursor += 1

proc setValues*(this: MpdListPane, values: seq[ptr mpd_song]) =
    this.cursor = 0
    this.currentViewLocation = 0
    this.songValues = values
    this.albumValues = albums_for(values)
    this.updateView()

proc drawTo*(state: ListState, nb: Nimbox, x, y: int) =
    for i, t in state.currentView:
        let style: Style =
            if i == state.cursor:
                styReverse
            else:
                styNone
        nb.print(x, y + i, t, clrDefault, clrDefault, style)
    #nb.print(this.x+100, this.y, $this.cursor)
    #nb.print(this.x+110, this.y, $this.currentViewLocation)
    #nb.print(this.x+100, this.y+1, $this.getCurrentValue())
