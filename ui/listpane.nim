import
    pane,
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
    songValues: seq[ptr mpd_song]
    albumValues: seq[mpd_album]
    wrap: bool # TODO actually implement
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
    if this.cursor == 0:
        this.moveViewUp()
    else:
        this.cursor -= 1

proc down*(this: MpdListPane) =
    if this.cursor == len(this.values)-1:
        return
    if this.cursor == this.height-1:
        this.moveViewDown()
    else:
        this.cursor += 1

proc setValues*(this: MpdListPane, values: seq[ptr mpd_song]) =
    this.cursor = 0
    this.currentViewLocation = 0
    this.songValues = values
    this.albumValues = albums_for(values)
    this.updateView()

proc drawTo*(this: MpdListPane, nb: Nimbox) =
    for i, t in this.currentView:
        let style: Style =
            if i == this.cursor:
                styReverse
            else:
                styNone
        nb.print(this.x, this.y + i, t, clrDefault, clrDefault, style)
