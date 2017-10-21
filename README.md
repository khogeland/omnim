## Omnim

Omnim is an omni search utility for MPD, displayed as an interactive list of results that updates as you type.

This is my first real Nim project, so the code surely has plenty of messiness, antipatterns, etc. Be warned.

### Usage

```bash
omnim
-s --songs    Search individual songs instead of albums.
-H --host     MPD host
-p --port     MPD port
-t --timeout  MPD connection timeout
-n --noninteractive [search-terms] Non-interactive mode (results to stdout)
```


### Building

```bash
git submodule update --init
nim c -d:release omnim.nim
```
