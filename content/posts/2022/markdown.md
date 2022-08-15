+++
title = "Making your own blog with Zola"
date = 2022-07-31
draft = true
+++

This post is just a markdown example. You don't need to read this. It's very
boring and exists only for demonstrating purposes. I use it to check out the
styling and layout of the website.

[Zola](https://www.getzola.org) is a static site generator, uses
[Tera](https://tera.netlify.app) template engine.

Some *italic text* and **bold text** and ~~strikethrough text~~ and `inline
code`. [^1]

Unordered list:
- One
- Two
- Three

Ordered list: [^2]
1. One
2. Two
3. Three

> A quote.
>
> It contains multiple paragraphs.

Let's check out how code blocks look. Here is a rust code block:

```rust
fn main() {
    println!("Hello world!");
}
```

A code block with more code. This time it's a toml file:

```toml
# The URL the site will be built for
base_url = "https://example.com"

# Whether to automatically compile all Sass files in the sass directory
compile_sass = true

# Whether to build a search index to be used later on by a JavaScript library
build_search_index = false

[markdown]
# Whether to do syntax highlighting
# Theme can be customised by setting the `highlight_theme` variable to a theme supported by Zola
highlight_code = true

[extra]
# Put all your custom variables here
```


# Heading 1

## Heading 2

### Heading 3

#### Heading 4

##### Heading 5

###### Heading 6

![An example image](https://plchldr.co/i/480x360?bg=EB6361)

![A large image](https://plchldr.co/i/1280x720?bg=3D8EB9)

---

[^1]: A footnote. Footnotes can be used for things that could have explanation or extra context, but
for which the explanation is not relevant or otherwise desirable to have inline.

[^2]: Another footnote.
