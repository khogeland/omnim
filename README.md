## Omnim

Omnim is an omni search utility for MPD, displayed as an interactive list of results that updates as you type.

### Usage

- Up/Down: Navigate list
- Enter: Replace queue with selection and play.
- Ctrl-Space: Add selection to queue.
- Ctrl-Z: Switch between song and album results.

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
