import
    unicode

type SearchBoxState* = ref object
    query*: seq[Rune]

type ListState* = ref object
    currentView*: seq[string]
    cursor*: int

proc initSearchBoxState*(): SearchBoxState =
    return SearchBoxState(query: @[])
proc initListState*(): ListState =
    return ListState(currentView: @[], cursor: 0)
