- Multiple-item selection.
- List line-wrapping.
- Setup nimble and publish as package.
- Nimbox bugs (to fix in my fork)
    - Unicode characters clobber each other and are left on screen when `clear` is called. Likely culprit would be either nimbox or termbox miscounting the length of strings due to multi-byte runes.
    - Nimbox always reports that Alt is held down (need to fix for text navigation)
    - Holding down Ctrl does totally bizarre things (Ctrl-Space = "2", Ctrl-[a-z] = capital letters, Ctrl-3 = Escape). Probably a single bug.
- Album mode should only return full-album results. This is difficult, because MPD doesn't have a concept of "album". Could perform an extra query for every "album" we create (probably best, should be quick.) Could optimize to only query albums that would be visible on screen.
- Text navigation.
