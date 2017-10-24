import 
    libmpdclient,
    parseopt2,
    os,
    re,
    strutils,
    sequtils,
    sets,
    tables,
    osproc,
    streams

import
    mpd/album,
    mpd/songutils,
    mpd/mpdctl,
    ui/ui

var host: string
var port: uint16 = 0
var timeout_ms: uint32 = 10000
var song_mode = false

var search_strings: seq[string] = @[]
var parser = initOptParser()
for kind, key, val in parser.getopt():
    case kind
    of cmdArgument:
        search_strings.add(key)
    of cmdLongOption, cmdShortOption:
        case key:
            of "s", "songs": song_mode = true
            of "H", "host": host = val
            of "p", "port": port = uint16(parseUInt(val))
            of "t", "timeout": timeout_ms = uint32(parseUInt(val))
    of cmdEnd: assert(false)

let uiResult = runUi(host, port, timeout_ms, songMode)
case uiResult.kind:
    of UiFailure:
        stderr.writeLine(uiResult.error)
        quit(QuitFailure)
    else: discard

