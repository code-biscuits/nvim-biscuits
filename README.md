# nvim-biscuits

Every dev needs something sweet sometimes. Code Biscuits are in-editor annotations usually at the end of a closing tag/bracket/parenthesis/etc. They help you get the context of the end of that AST node so you don't have to navigate to find it.

## Demo

Here you can see the plugin being used on a Go file with `cursor_line_only` turned on.

![Demo of the plugin being used on a Golang file](./assets/demo.gif)

## Installation

In your nvim config, add the Plug dependencies:

Using Vim Plug:

```lua
call plug#begin()
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'code-biscuits/nvim-biscuits'
call plug#end()
```
Using Packer:

```lua
use {
  'code-biscuits/nvim-biscuits',
  requires = {
    'nvim-treesitter/nvim-treesitter',
     run = ':TSUpdate'
  },
}

```

You will also need to configure which language parsers you want to have enabled for tree-sitter. "maintained" currently will install 40 languages. "all" will install even more.

```lua
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained",
  ...
}
EOF
```

## Configuration

Basic configuration is simple:

```lua
lua require('nvim-biscuits').setup({})
```

You can also configure your own global defaults as well as language specific defaults.

This is just an example config.

```lua
lua <<EOF
require('nvim-biscuits').setup({
  default_config = {
    max_length = 12,
    min_distance = 5,
    prefix_string = " 📎 "
  },
  language_config = {
    html = {
      prefix_string = " 🌐 "
    },
    javascript = {
      prefix_string = " ✨ ",
      max_length = 80
    },
    python = {
      disabled = true
    }
  }
})
EOF
```

## Configuration (Custom events)

If you want to decorate only on specific vim events you can use the `on_events` config option. It is a string that takes in a comma separated list of vim autocmd events ([http://vimdoc.sourceforge.net/htmldoc/autocmd.html#autocmd-events](http://vimdoc.sourceforge.net/htmldoc/autocmd.html#autocmd-events))

This example only updates the biscuits when leaving insert mode or hold the cursor in one place for long enough.

```lua
lua <<EOF
require('nvim-biscuits').setup({
  on_events = { 'InsertLeave', 'CursorHoldI' }
})
EOF
```

## Configuration (Virtual Text Color)

You can configure the `highlight` group in your init.vim:

```lua

" global color
highlight BiscuitColor ctermfg=cyan

" language specific color
highlight BiscuitColorRust ctermfg=red

```

## Configuration (Disabling Languages)

You may have tree-sitter set up for some languages in which you don't want nvim-biscuits to show up. Since we just use whatever supported languages tree-sitter has by default, you must disable languages individually.

To disable nvim-biscuits for any language, simply add `{ mylanguage = {disabled = true} }` to `language_config` field in setup. (where `mylanguage` is the language that you want to disable. eg: `python`, `dart`, etc)

## Configuration (Trim by words)

Using this settings, you can dictate the max length of a biscuit using whole words rather than just characters. The `max_length` determines how many words will show when this setting is enabled.

```lua
lua <<EOF
require('nvim-biscuits').setup({
  max_length = 2,
  trim_by_words = true,
})
EOF
```

## Configuration (Keybinding to toggle visibility)

You can show or hide the biscuits by placing a `toggle_keybind` at the root of your config or inside a language config.

We also expose an optional flag, `show_on_start`, to enable biscuits to show on initial load. This value defaults to `false`;

```lua
lua <<EOF
require('nvim-biscuits').setup({
  toggle_keybind = "<leader>cb",
  show_on_start = true -- defaults to false
})
EOF
```

OR

```lua
lua <<EOF
require('nvim-biscuits').setup({
  language_config = {
    rust = {
      toggle_keybind = "<leader>cb"
    }
  }
})
EOF
```

If you prefer to bind manually, the function is exposed as:

```lua
require('nvim-biscuits').toggle_biscuits()
```

## Configuration (Cursor Line Only)

You can configure the biscuits to only show on the line that has your cursor. This can be useful if you find that default config makes the text too cluttered

```lua
lua <<EOF
require('nvim-biscuits').setup({
  cursor_line_only = true
})
EOF
```

## Supported Languages

We currently support all the languages supported in tree-sitter. Not all languages have specialized support, though most will probably need some.

As we make tailored handlers for specific languages we will create a table here to track that.

## Development

While doing local dev, it can be nice to use the `utils.console_log` command to write runtime logs to `~/.cache/nvim/nvim-biscuits.log`.

You can turn this on by passing DEBUG=true as an environment variable when launching Neovim.

## License

Copyright 2021 Chris Griffing

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
