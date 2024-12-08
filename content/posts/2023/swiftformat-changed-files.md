+++
title = "SwiftFormat only changed files"
description = "How to run swiftformat or swiftlint and other tools only on changed files leveraging awk"
date = 2023-01-07
[taxonomies]
tags = ["swift", "git", "awk", "bash"]
+++

There are a couple of reasons to run formatting or linting tools only on files
that have been changed. In a big legacy project you probably don't want to
format all files right away. Also you don't want spending extra seconds running
these kinds of tools.

> I want to note that [nicklockwood/SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
> uses caching by default, so the second point might be irrelevant. 

One solution is to use git to identify files that have been changed and run
swiftformat on those. When I decided to implement this strategy I found a
snippet of a bash script that does what I need. At least, I thought.

```bash
git diff --diff-filter=d --name-only | grep -e '\(.*\).swift$' | while read line; do
    swiftformat  --swiftversion 5.0 "${line}";
done
```

Let's see what is going on here. It uses `git diff` subcommand with argument
`--diff-filter=d` and `--name-only` flag. `--diff-filter=d`, according to
documentation, excludes paths for files that have been deleted, `--name-only`
shows only file paths. The output of `git diff` is piped to `grep` with a regex
to filter only `swift` files and then the result is piped to the `while` loop
in which we run swiftformat for each file path.

This looks logical. You put this snippet in a file, make it executable and
add it in a build phase in your Xcode project. It works in almost all cases.
After working with this setup for a while I've noticed, for example, that this
doesn't handle newly created files. It is a bummer and completely unexpected.

I didn't find any other solution, so I decided to look at `git status`. Seems
like it knows and shows newly created, changed and renamed files. That is what
we need. `git status` also has `--porcelain` flag which adds guaranties that
format of the output doesn't change between git versions. Let's explore this
solution further. If you run `git status --porcelain`, you'll see the output
that looks something like this:
```
A  file.swift
?? another-file.swift
```

Basically, it's a table with a status and a file path for each file. Our task
is to filter the output of `git status --porcelain` by statuses and return
file paths. This should be pretty easy to do in any programming language. I was
thinking about using swift for this but decided to go against it. I don't want
to impose a compilation step on the team. Another reason was that I wanted to
try `awk` :). For those who don't know, `awk` is a text processing language and
a tool. It is installed by default on every unix and linux. Since macos is a
descendant of unix, we have it too. Nice!

Next step is to read the documentation about different statuses. `git status
--help`.  Ok, I think I understand the gist. Let's try it in practice and see
what we are dealing with. The statuses that we are interested in are:
- `M`- modified
- `A`- added
- `AM`- added and modified
- `??` - newly created untracted files
- `R` - renamed
- `RM` - renamed and modified

Seems like the above list is complete for our use case.


It's time to try `awk` for real. You probably saw usage of `awk` in some
scripts and maybe it looked like one-liner in a bash command. But here we have
a lot to handle. So I decided to put all logic in a separate file and pass it
to `awk` using `-f` argument. Now I'll show you the script that evolved during
my late evening working on this:
```awk
{
  if ($1 == "M" || $1 == "A" || $1 == "AM" || $1 == "??") {
    if (match($0, /".*"/) != 0) {
      print substr($0, RSTART+1, RLENGTH-2)
    } else {
      print $2
    }
  } else if ($1 == "R" || $1 == "RM") {
    if (match($0, /->/) != 0) {
      path = substr($0, RSTART+3)
      if (match(path, /".*"/) != 0) {
        print substr(path, RSTART+1, RLENGTH-2)
      } else {
        print path
      }
    }
  }
}
```

Let's pretend it's beautiful :)

No, it is not! But it handles all cases that we're interested in.

I'll explain the script a little bit. The `awk` treats each line in the input
as a record. A record consists of fields. By default, fields are separated
by a space. To access individual fields you can use variables `$1`, `$2` etc.
The `$0` has the whole record. Here, in the top level `if else` block we are
checking statuses. `R` and `RM` should be handled separately because they have
different format for file paths incorporating `->` to show the renaming. We are
interested in already renamed file, hence `match($0, /->/)` and taking what is
to the right of `->`. This script also handles file names with spaces in them.
We use the `match($0, /".*"/)` to find double quotes and taking the part that
is inside them. Now I think you understand the script pretty well. I put it in
a file and named it `git-changed-files.awk`

Let's modify our formatting script:
```bash
git status -uall --porcelain | awk -f git-changed-files.awk | grep -e '\(.*\).swift$' | while read line; do
    swiftformat  --swiftversion 5.0 "${line}";
done
```

Note that I've included `-uall` argument in `git status` command to make it
extra clear we are interested in untracted files too. Otherwise, if you create
a new directory and a new swift file inside it, it will only show the path to
the directory, not a file path.

You can take a look how I use it in my test project
[GitHeart](https://github.com/zummenix/GitHeart) on github.

## Conclusion

In overall, this solution is simple and doesn't require any additional tools to
install. Also the script might be useful to run other tools. I'm glad that I've
tried `awk` and learned a little bit about it. The knowledge will be helpful
next time I need to process text in nontrivial way.
