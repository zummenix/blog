+++
title = "Disable Spotlight and life without it"
description = "mds_store uses a lot of cpu indexing files for Spotlight (most likely just stuck)"
date = 2024-12-02
[taxonomies]
tags = ["macos", "bash", "shorts"]
+++

I've recently noticed that the `mds_stores` process on my Mac is consuming a
significant amount of CPU power. Again.

`mds_stores` is a background process that indexes files for faster searching in
Spotlight. Seasoned macOS users very likely know about it and know that wise
decision would be to disable some of search areas by changing Spotlight settings.
This is me too. I have only Applications, Calculator and System Settings items
enabled and still `mds_stores` is the first in the list of cpu consumers in
Activity Monitor. I'm not sure if it happened after updating macOS or earlier
for some other reason.

Something needs to be done. This is last straw :)

I'm disabling Spotlight completely:

```bash
sudo mdutil -ai off
```

It spat out the following:
```
/:
2024-11-22 00:21:40.119 mdutil[25437:982881] mdutil disabling Spotlight: / -> kMDConfigSearchLevelFSSearchOnly
        Indexing disabled.
/System/Volumes/Data:
2024-11-22 00:21:40.144 mdutil[25437:982881] mdutil disabling Spotlight: /System/Volumes/Data -> kMDConfigSearchLevelFSSearchOnly
Error: unable to perform operation.  (-1)
        Error: unknown indexing state.
/System/Volumes/Preboot:
Error: invalid operation.
        Error: unknown indexing state.
```

Maybe these errors are somehow related to the problem. After running the command
second time it reported that indexing is disabled without any errors.

It's sad to loose Spotlight functionality. Brief research revealed existence of
similar apps such as [Alfred](https://www.alfredapp.com) or
[Raycast](https://www.raycast.com). I haven't tried them because I probably
can't use most of their features. Eventually I figured that I can write
simple alternatives for my needs myself. That I did.

The main feature of Spotlight that I miss the most is fast opening any app by
typing in Spotlight search field. The solution would be to search the `*.app`
in special directories. Filter/search could be done using 
[`fzf`](https://junegunn.github.io/fzf/) (or similar tools). And opening an
app will be done using native Apple script. Here is the first working script
in bash:

```bash
#!/usr/bin/env bash

function list_apps {
    find "$1" -type d -maxdepth 1 -name '*.app' | sed 's#.*/##' | sed 's/.app$//'
}

paste -d'\n' <(list_apps /Applications) <(list_apps /System/Applications) <(list_apps /System/Applications/Utilities) | \
    xargs -I{} echo "{}" | \
    sort -if | \
    fzf --header "Select app to open" | \
    xargs -I{} osascript -e "tell application \"{}\" to activate"
```

Here is how it looks:

<div>
<script src="https://asciinema.org/a/693053.js" id="asciicast-693053" async="true"></script>
</div>

I'll probably update this script in the future if I find any bugs or find myself
missing some features. You can always check my dotfiles for that
[here](https://github.com/zummenix/dotfiles/tree/master/scripts).

For now I'm happy with this simple solution, knowing that `mds_stores` won't
use any cpu to no purpose.
