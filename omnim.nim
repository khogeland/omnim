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

#TODO interactive menu in response to command-line query
#proc launch_menu(options: seq[string]): string = discard

proc main(cmdline: seq[string]): int =
    var host: string
    var port: uint16 = 0
    var timeout_ms: uint32 = 10000
    var song_mode = false
    var interactive = true
    #var show_list = false

    var search_strings: seq[string] = @[]
    var parser = initOptParser()
    for kind, key, val in parser.getopt():
        case kind
        of cmdArgument:
            search_strings.add(key)
        of cmdLongOption, cmdShortOption:
            case key:
                of "n", "noninteractive": interactive = false
                #of "l", "show-list": show_list = true
                of "s", "songs": song_mode = true
                of "H", "host": host = val
                of "p", "port": port = uint16(parseUInt(val))
                of "t", "timeout": timeout_ms = uint32(parseUInt(val))
        of cmdEnd: assert(false)

    var conn: ptr mpd_connection
    defer:
        conn.mpd_connection_free()
    conn = mpd_connection_new(cast[cstring](host), port, timeout_ms)
    if conn.mpd_connection_get_error() != MPD_ERROR_SUCCESS:
        echo(conn.mpd_connection_get_error_message)
        return 1

    var mpdCtl = initMpdCtl(host, port, timeout_ms)
    defer: mpdCtl.close()

    if interactive:
        startUi(mpdCtl, songMode)
    elif len(search_strings) > 0:
        if song_mode:
            echo(mpdCtl.searchSongs(search_strings))
        else:
            echo(mpdCtl.searchAlbums(search_strings))
 
    return 0

quit(main(os.commandLineParams()))
