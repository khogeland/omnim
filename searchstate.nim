import
    libmpdclient,
    sequtils,
    algorithm,
    tables

import
    mpd/album,
    mpd/songutils,
    mpd/mpdctl

type SearchState*[T] = ref object
    mpdCtl: MpdCtl
    listOptions: Table[string, T]
    searchProc: proc(mpdCtl: MpdCtl, s: string): seq[T]

proc initAlbumSearchState*(mpdCtl: MpdCtl): SearchState[mpd_album] =
    return SearchState[mpd_album](mpdCtl: mpdCtl, listOptions: initTable[string, mpd_album](), searchProc: searchAlbums)

proc initSongSearchState*(mpdCtl: MpdCtl): SearchState[ptr mpd_song] =
    return SearchState[ptr mpd_song](mpdCtl: mpdCtl, listOptions: initTable[string, ptr mpd_song](), searchProc: searchSongs)

proc search*[T](this: SearchState[T], query: string): seq[string] =
    var results = this.searchProc(this.mpdCtl, query)
    this.listOptions = results.map(proc(t: T): (string, T) = ($t, t)).toTable
    return sorted(toSeq(this.listOptions.keys), cmp)

proc getResult*[T](this: SearchState[T], key: string): T =
    return this.listOptions[key]

